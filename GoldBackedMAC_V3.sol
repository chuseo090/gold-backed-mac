// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// =================================================================================
// 1. UUPS Proxy Standard Libraries (Remix Compatible - Local Implementation)
// =================================================================================

// Context: msg.sender 및 msg.data를 제공하는 기본 추상 컨트랙트
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// Initializable: 초기화 로직을 보장하는 컨트랙트 (constructor 대신 initialize 사용)
abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");
        bool isInitializing = _initializing;
        _initializing = true;
        _initialized = true;
        _;
        _initializing = isInitializing;
    }
}

// OwnableUpgradeable: 소유권 관리 (업그레이드 가능 버전에 맞춤)
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
        // ✨ 이 부분이 Remix에서 문제없이 작동하도록 Context를 상속받아 수정했습니다.
        require(owner() == _msgSender(), "Ownable: caller is not the owner"); 
        _;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    // 이 외의 함수 (renounceOwnership, transferOwnership)는 로직 구현에서 생략 가능
}

// UUPSUpgradeable: UUPS 표준을 따르는 업그레이드 로직 (Transparent Proxy와의 충돌 방지)
abstract contract UUPSUpgradeable is Initializable {
    
    // 💡 ERC1967 Storage Slot: UUPS를 위한 식별자 (OpenZeppelin 표준)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function _authorizeUpgrade(address newImplementation) internal virtual;

    function __UUPSUpgradeable_init() internal initializer {}

    // upgradeTo 및 기타 표준 함수는 프록시 계약에 의해 처리되므로,
    // 로직 계약인 이 파일에서는 _authorizeUpgrade만 구현합니다.
}


// =================================================================================
// 3. OpenZeppelin IERC20.sol (Interface for MAC Token)
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
// 4. GoldBackedMAC_V3 (Implementation Contract - 실제 로직 계약)
// =================================================================================
contract GoldBackedMAC_V3 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    // 상태 변수 (Storage Variables - 순서 주의!)
    // UUPS에서 상태 변수 선언 순서는 매우 중요합니다.
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

    // 이벤트 정의
    event Mint(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev 컨트랙트 초기화 함수 (Constructor 대체)
     * 이 함수는 배포 후 딱 한 번만 호출되어야 합니다.
     */
    function initialize(address _macTokenAddress) public initializer {
        // UUPS 및 Ownable 초기화
        __Ownable_init(_msgSender()); // 배포자를 Owner로 설정
        __UUPSUpgradeable_init(); // UUPS 초기화
        
        // GMA-04 해결: MAC 토큰 주소에 대한 제로 주소 검증
        require(_macTokenAddress != address(0), "Invalid MAC token address");

        // MyAwesomeCoin 컨트랙트 주소를 저장
        macToken = IERC20Extended(_macTokenAddress);
    }
    
    /**
     * @dev UUPS 표준: 업그레이드 권한 부여 함수.
     * UUPSUpgradeable 계약은 이 함수를 구현해야 합니다.
     * onlyOwner (Owner만 업그레이드 가능)로 구현되었습니다.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    // --- GMA-02 해결을 위한 헬퍼 함수: 소수점 정규화 ---
    function _scaleAmount(uint256 amount, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return amount;
        } else if (fromDecimals < toDecimals) {
            return amount * (10**(toDecimals - fromDecimals));
        } else {
            return amount / (10**(fromDecimals - toDecimals));
        }
    }


    // --- ERC20 필수 기능 구현 (Gold-Backed Token) ---

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

    /**
     * @dev MAC 토큰을 담보로 Gold-Backed 토큰을 발행합니다.
     */
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

    /**
     * @dev Gold-Backed 토큰을 소각하고 담보된 MAC 토큰을 돌려받습니다.
     */
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
