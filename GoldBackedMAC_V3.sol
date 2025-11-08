// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// =================================================================================
// 1. UUPS Proxy Standard Libraries
// =================================================================================

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;

    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized) {
            revert("Initializable: contract is already initialized");
        }
        _initialized = true;
    }

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");
        bool isInitializing = _initializing;
        _initializing = true;
        _initialized = true;
        _;
        _initializing = isInitializing;
    }
}

abstract contract OwnableUpgradeable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init(address initialOwner) internal initializer {
        _transferOwnership(initialOwner);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner"); 
        _;
    }

    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract UUPSUpgradeable is Initializable {
    
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function _authorizeUpgrade(address newImplementation) internal virtual;

    function __UUPSUpgradeable_init() internal initializer {}
    
    // ✨ V4.4 수정: onlyOwner 모디파이어를 제거하고, 구현 계약에서 재정의하도록 함
    function upgradeTo(address newImplementation) public virtual {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }
    
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        require(newImplementation != address(0), "UUPS: new implementation is the zero address"); 
        
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
        
        if (data.length > 0 || forceCall) {
            (bool success, bytes memory returndata) = newImplementation.delegatecall(data);
            require(success, string(abi.encodePacked("UUPS: upgrade failed ", returndata)));
        }
    }
}


// =================================================================================
// 3. OpenZeppelin IERC20.sol
// =================================================================================
interface IERC20Extended { 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

// =================================================================================
// 4. GoldBackedMAC_V3 (Implementation Contract)
// =================================================================================
contract GoldBackedMAC_V3 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    // 상태 변수 (Storage Variables)
    IERC20Extended public macToken;

    uint256 public constant COLLATERAL_RATIO_NUMERATOR = 15;
    uint256 public constant COLLATERAL_RATIO_DENOMINATOR = 10;
    
    uint8 public constant G_MAC_DECIMALS = 18;

    string public constant name = "Gold-Backed MyAwesomeCoin";
    string public constant symbol = "G-MAC";
    uint8 public constant decimals = G_MAC_DECIMALS; 
    
    uint256 private _totalSupply;
    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Storage Gap
    uint256[50] private __gap;

    // 이벤트 정의
    event Mint(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Logic Contract 직접 초기화 방지
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); 
    }

    /**
     * @dev 컨트랙트 초기화 함수
     */
    function initialize(address _macTokenAddress) public initializer {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();
        
        require(_macTokenAddress != address(0), "Invalid MAC token address");

        macToken = IERC20Extended(_macTokenAddress);
    }

    // ✨ V4.4 수정: upgradeTo 함수를 구현 계약에서 onlyOwner를 붙여 재정의
    function upgradeTo(address newImplementation) public override onlyOwner {
        _authorizeUpgrade(newImplementation);
        // _upgradeToAndCallUUPS는 UUPSUpgradeable 내에서 호출됨
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    // --- 헬퍼 함수: 소수점 정규화 ---
    function _scaleAmount(uint256 amount, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return amount;
        } else if (fromDecimals < toDecimals) {
            return amount * (10**(toDecimals - fromDecimals));
        } else {
            return amount / (10**(fromDecimals - toDecimals));
        }
    }


    // --- ERC20 필수 기능 구현 ---

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[from] >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function mint(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        
        require(macToken.transferFrom(_msgSender(), address(this), amount), "MAC token transfer failed");
        
        uint8 macDecimals = macToken.decimals();
        uint256 scaledAmount = _scaleAmount(amount, macDecimals, G_MAC_DECIMALS);

        uint256 mintAmount = (scaledAmount * COLLATERAL_RATIO_DENOMINATOR) / COLLATERAL_RATIO_NUMERATOR;

        unchecked {
            balanceOf[_msgSender()] += mintAmount;
            _totalSupply += mintAmount;
        }
        
        emit Mint(_msgSender(), mintAmount);
        emit Transfer(address(0), _msgSender(), mintAmount);
    }

    function redeem(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf[_msgSender()] >= amount, "Insufficient G-MAC balance");
        
        uint256 collateralToReturnScaled = (amount * COLLATERAL_RATIO_NUMERATOR) / COLLATERAL_RATIO_DENOMINATOR;
        
        uint8 macDecimals = macToken.decimals();
        uint256 collateralToReturn = _scaleAmount(collateralToReturnScaled, G_MAC_DECIMALS, macDecimals);
        
        unchecked {
            balanceOf[_msgSender()] -= amount;
            _totalSupply -= amount;
        }
        
        require(macToken.transfer(_msgSender(), collateralToReturn), "MAC token transfer failed");
        
        emit Redeem(_msgSender(), amount);
        emit Transfer(_msgSender(), address(0), amount);
    }
}

