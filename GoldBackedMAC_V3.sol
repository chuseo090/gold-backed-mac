// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// =================================================================================
// 0. UUPS 필수 인터페이스 추가
// =================================================================================

interface IERC1822Proxiable {
    function proxiableUUID() external pure returns (bytes32); 
}

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
    
    // 🌟 GF1-04 최종 해결: Initializable에도 __gap 추가
    uint256[50] private __gap;
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

    // GF1-08 수정: Zero Address 검증 추가
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    // 🌟 GF1-04 최종 해결: OwnableUpgradeable에도 __gap 추가
    uint256[50] private __gap;
}

// ⚠️ 상속 구조 수정: OwnableUpgradeable 상속 추가! (오류 해결)
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable, OwnableUpgradeable {
    
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function _authorizeUpgrade(address newImplementation) internal virtual;

    function __UUPSUpgradeable_init() internal initializer {}
    
    // UUPS 호환성 ID 반환
    function proxiableUUID() external pure override returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    // GF1-02 문제 3 해결: calldata 없이 업그레이드
    function upgradeTo(address newImplementation) public virtual {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }
    
    // 🚨 문제 1 해결: onlyOwner 모디파이어 추가
    function upgradeToAndCall(address newImplementation, bytes memory data) public virtual onlyOwner {
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    // GF1-02 문제 2 해결 및 문제 3 코드 검사 추가
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        require(newImplementation != address(0), "UUPS: new implementation is the zero address");
        
        // 🧱 문제 3 해결: 새 구현 주소에 코드가 있는지 확인
        uint256 size;
        assembly {
            size := extcodesize(newImplementation)
        }
        require(size > 0, "UUPS: implementation is not a contract");

        // 새로운 구현 계약이 UUPS 표준을 따르는지 확인 (브릭 방지)
        require(IERC1822Proxiable(newImplementation).proxiableUUID() == slot, "UUPS: not UUPS compatible");
        
        assembly {
            sstore(slot, newImplementation)
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
contract GoldBackedMAC_V3 is Initializable, UUPSUpgradeable {
    
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
    
    // GF1-04 수정: Storage Gap (여기도 유지)
    uint256[50] private __gap;

    // 이벤트 정의
    event Mint(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // GF1-09 수정: Logic Contract 직접 초기화 방지
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

    // GF1-02 문제 1 해결: upgradeTo 오버라이드 시, 핵심 업그레이드 로직 호출
    function upgradeTo(address newImplementation) public override onlyOwner {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
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

        // 🌟 최종 수정: Mint 로직을 DENOMINATOR / NUMERATOR (10/15)로 수정!
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
        
        // Redemption은 그대로 NUMERATOR / DENOMINATOR (15/10) 유지
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



