// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// =================================================================================
// 1. OpenZeppelin Context.sol (Abstract base for gas savings)
// =================================================================================
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// =================================================================================
// 2. OpenZeppelin Ownable.sol (Access control)
// =================================================================================
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// =================================================================================
// 3. OpenZeppelin IERC20.sol (Interface for MAC Token)
// ** Decimals 정보 조회를 위해 IERC20 대신 ERC20 표준 인터페이스를 사용합니다. **
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
    function decimals() external view returns (uint8); // GMA-02 해결을 위해 추가
}

// =================================================================================
// 4. GoldBackedMAC.sol (Your main contract logic)
// =================================================================================
contract GoldBackedMAC is Ownable {
    // 담보로 사용되는 MAC 토큰 컨트랙트의 인터페이스 (Extended 사용)
    IERC20Extended public macToken;

    // GMA-01 해결: 개인별 담보 기록(collateralAmount) 매핑은 제거됩니다.
    // G-MAC 토큰이 ERC-20으로 유동성을 갖기 위해 컨트랙트 전체 담보만 사용합니다.

    // 담보 대비 발행 비율 (G-MAC의 최종 목표인 1.5배 초과 담보를 가정하고 COLLATERAL_RATIO를 1.5로 설정합니다.)
    // GMA-02 해결: 비율 계산을 위한 SCALE_FACTOR를 추가하여 소수점 없는 정수 계산을 지원합니다.
    uint256 public constant COLLATERAL_RATIO_NUMERATOR = 15; // 150% (1.5)
    uint256 public constant COLLATERAL_RATIO_DENOMINATOR = 10;
    
    // G-MAC의 소수점 자릿수 (ERC20 표준)
    uint8 public constant G_MAC_DECIMALS = 18;

    // Gold-Backed 토큰의 메타데이터
    string public constant name = "Gold-Backed MyAwesomeCoin";
    string public constant symbol = "G-MAC";
    uint8 public constant decimals = G_MAC_DECIMALS; 
    
    // 발행된 Gold-Backed 토큰의 총 공급량 및 사용자 잔액
    uint256 private _totalSupply;
    mapping(address => uint256) public balanceOf;

    // allowance 매핑 추가 (ERC20 표준 준수를 위해)
    mapping(address => mapping(address => uint256)) private _allowances;

    // 이벤트 정의
    event Mint(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev 컨트랙트 생성자
     * @param _macTokenAddress 담보로 사용될 MyAwesomeCoin (MAC)의 ERC20 컨트랙트 주소
     * GMA-03 해결: 사용되지 않는 _oracleAddress 인자를 제거했습니다.
     */
    constructor(address _macTokenAddress) Ownable(_msgSender()) {
        // GMA-04 해결: MAC 토큰 주소에 대한 제로 주소 검증 추가
        require(_macTokenAddress != address(0), "Invalid MAC token address");

        // MyAwesomeCoin 컨트랙트 주소를 저장합니다.
        macToken = IERC20Extended(_macTokenAddress);
    }

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
     * @param amount 담보로 제공할 MAC 토큰의 양 (MAC 토큰의 decimals 기준)
     */
    function mint(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        
        // 사용자로부터 MAC 토큰을 이 컨트랙트로 전송
        require(macToken.transferFrom(_msgSender(), address(this), amount), "MAC token transfer failed");
        
        // GMA-01 해결: 개인 담보 기록 업데이트 로직 제거
        
        // GMA-02 해결: MAC 토큰의 amount 단위를 G-MAC 단위로 정규화 (1:1 가치 기준으로 맞춤)
        uint8 macDecimals = macToken.decimals();
        uint256 scaledAmount = _scaleAmount(amount, macDecimals, G_MAC_DECIMALS);

        // Gold-Backed 토큰 발행 (초과 담보 비율 적용)
        // mintAmount = scaledAmount * 1 / 1.5 (G-MAC 발행량은 MAC 담보량보다 적어야 함)
        uint256 mintAmount = (scaledAmount * COLLATERAL_RATIO_DENOMINATOR) / COLLATERAL_RATIO_NUMERATOR;

        // ERC20 잔액 업데이트
        unchecked {
            balanceOf[_msgSender()] += mintAmount;
            _totalSupply += mintAmount;
        }
        
        emit Mint(_msgSender(), mintAmount);
        emit Transfer(address(0), _msgSender(), mintAmount);
    }

    /**
     * @dev Gold-Backed 토큰을 소각하고 담보된 MAC 토큰을 돌려받습니다.
     * @param amount 소각할 Gold-Backed 토큰의 양 (G-MAC의 decimals 기준)
     */
    function redeem(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf[_msgSender()] >= amount, "Insufficient G-MAC balance");
        
        // 필요한 담보 계산 (초과 담보 비율을 역산하여 돌려줄 MAC 토큰의 양을 계산)
        // collateralToReturn = amount * 1.5 (G-MAC 소각량보다 돌려줄 MAC 담보량이 많아야 함)
        uint256 collateralToReturnScaled = (amount * COLLATERAL_RATIO_NUMERATOR) / COLLATERAL_RATIO_DENOMINATOR;
        
        // GMA-02 해결: 돌려줄 MAC 토큰의 단위를 MAC 토큰의 decimals에 맞게 조정
        uint8 macDecimals = macToken.decimals();
        uint256 collateralToReturn = _scaleAmount(collateralToReturnScaled, G_MAC_DECIMALS, macDecimals);
        
        // GMA-01 해결: 개인 담보 확인 로직 제거
        
        // 컨트랙트가 충분한 MAC 잔액을 가지고 있는지 확인 (전송 로직에서 간접적으로 검증됨)
        
        // Gold-Backed 토큰 소각
        unchecked {
            balanceOf[_msgSender()] -= amount;
            _totalSupply -= amount;
        }
        
        // GMA-01 해결: 개인 담보 기록 업데이트 로직 제거
        
        // 담보 MAC 토큰을 사용자에게 반환
        // (이 transfer 호출이 컨트랙트에 MAC 잔액이 충분한지 확인하는 역할을 겸합니다)
        require(macToken.transfer(_msgSender(), collateralToReturn), "MAC token transfer failed");
        
        emit Redeem(_msgSender(), amount);
        emit Transfer(_msgSender(), address(0), amount);
    }
}
