// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2; 
pragma solidity ^0.8.30;
import "./IERC20.sol"; 
import "./Ownable.sol"; // Context.sol은 업로드하지 않습니다.

contract GoldBackedMAC is Ownable {
    // 담보로 사용되는 MAC 토큰 컨트랙트의 인터페이스
    IERC20 public macToken;

    // 담보된 MAC 토큰을 추적하는 매핑: 사용자 주소 => 담보된 MAC 수량
    mapping(address => uint256) public collateralAmount;

    // 담보 대비 발행 비율 (1:1 비율로 가정)
    uint256 public constant COLLATERAL_RATIO = 1;

    // Gold-Backed 토큰의 메타데이터
    string public constant name = "Gold-Backed MyAwesomeCoin";
    string public constant symbol = "G-MAC";
    uint8 public constant decimals = 18;
    
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
     * @param _secondArg 가격 오라클 컨트랙트의 주소 
     */
    constructor(address _macTokenAddress, address _secondArg) Ownable(msg.sender) { // <--- 이 부분은 유지됩니다.
        // MyAwesomeCoin 컨트랙트 주소를 저장합니다.
        macToken = IERC20(_macTokenAddress);
        // _secondArg는 사용되지 않지만, 배포 당시의 인수가 2개이므로 그대로 둡니다.
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
     * @param amount 담보로 제공할 MAC 토큰의 양
     */
    function mint(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        
        // 사용자로부터 MAC 토큰을 이 컨트랙트로 전송
        require(macToken.transferFrom(_msgSender(), address(this), amount), "MAC token transfer failed");
        
        // 담보 기록 업데이트
        collateralAmount[_msgSender()] += amount;
        
        // Gold-Backed 토큰 발행 (1:1 비율)
        uint256 mintAmount = amount / COLLATERAL_RATIO;
        balanceOf[_msgSender()] += mintAmount;
        _totalSupply += mintAmount;
        
        emit Mint(_msgSender(), mintAmount);
        emit Transfer(address(0), _msgSender(), mintAmount);
    }

    /**
     * @dev Gold-Backed 토큰을 소각하고 담보된 MAC 토큰을 돌려받습니다.
     * @param amount 소각할 Gold-Backed 토큰의 양
     */
    function redeem(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf[_msgSender()] >= amount, "Insufficient G-MAC balance");
        
        // 필요한 담보 계산
        uint256 collateralRequired = amount * COLLATERAL_RATIO;
        require(collateralAmount[_msgSender()] >= collateralRequired, "Insufficient collateral");
        
        // Gold-Backed 토큰 소각
        balanceOf[_msgSender()] -= amount;
        _totalSupply -= amount;
        
        // 담보 기록 업데이트
        collateralAmount[_msgSender()] -= collateralRequired;
        
        // 담보 MAC 토큰을 사용자에게 반환
        require(macToken.transfer(_msgSender(), collateralRequired), "MAC token transfer failed");
        
        emit Redeem(_msgSender(), amount);
        emit Transfer(_msgSender(), address(0), amount);
    }
}