# G-MAC (Gold-Backed MyAwesomeCoin) Core Contract

## 🌟 프로젝트 개요 (Overview)

**G-MAC**은 이더리움 기반의 담보형 스테이블 토큰 프로토콜입니다. 저희는 **MyAwesomeCoin (MAC)**을 담보(Collateral)로 활용하여 **1:1 비율**로 G-MAC 토큰을 발행하고 소각합니다. 이는 사용자에게 금 기반 자산에 대한 탈중앙화된 접근성을 제공하는 것을 목표로 합니다.

* **토큰 이름:** Gold-Backed MyAwesomeCoin (G-MAC)
* **토큰 심볼:** G-MAC
* **표준:** ERC-20
* **담보 자산:** MyAwesomeCoin (MAC Token)

## ⚙️ 핵심 메커니즘 (Core Mechanism)

G-MAC의 핵심 로직은 `GoldBackedMAC.sol` 계약에 구현되어 있으며, 주로 두 가지 기능으로 작동합니다.

| 기능 | 설명 | 담보 자산 처리 |
| :--- | :--- | :--- |
| **`mint(uint256 amount)`** | 사용자가 MAC 토큰을 예치하고 G-MAC 토큰을 **발행**합니다. | 사용자 MAC 토큰을 계약 주소로 **전송 및 잠금** |
| **`redeem(uint256 amount)`** | 사용자가 G-MAC 토큰을 **소각**하고 잠겨있던 MAC 담보를 회수합니다. | 계약에 잠겨있는 MAC 토큰을 사용자에게 **반환** |

**담보 비율:** 현재 `COLLATERAL_RATIO`는 1:1로 설정되어 있습니다. (1 MAC 당 1 G-MAC 발행)

## 🛡️ 보안 및 감사 상태 (Security and Audit Status)

G-MAC 팀은 보안을 최우선으로 생각합니다. 이 저장소의 코드는 메인넷 배포 전 **전문 보안 감사**를 진행할 예정입니다.

* **코드 상태:** 현재 테스트넷 배포 버전 (v0.9.0)
* **감사 진행 예정:** **CertiK**에 견적 요청 완료.
* **감사 목표:** 재진입 공격, 산술 오버플로우/언더플로우, 그리고 담보 로직의 무결성 검증.
* **감사 보고서:** 감사가 완료되는 대로 이 저장소에 게시될 예정입니다.

## 🔗 계약 정보 (Contract Details)

| 항목 | 값 |
| :--- | :--- |
| **G-MAC 컨트랙트 주소 (Testnet)** | `0xcd014ea2f6bb4d008a9f2fce571a8d4866565a80` |
| **사용된 Solidity 버전** | `^0.8.30` |
| **사용된 라이브러리** | OpenZeppelin (Context, Ownable, IERC20) |

## 🛠️ 빌드 및 테스트 (Build and Test)

### 필수 환경 (Prerequisites)

* Node.js (LTS 버전 권장)
* Yarn 또는 npm
* Hardhat 또는 Foundry (개발 환경에 맞춰 명시)

### 설치 및 컴파일

```bash
# 저장소 복제
git clone [https://github.com/chuseo090/gold-backed-mac](https://github.com/chuseo090/gold-backed-mac)
cd gold-backed-mac

# 의존성 설치
yarn install 
# 또는
npm install

# 컨트랙트 컴파일
npx hardhat compile
# 또는 (Foundry 사용 시)
forge build

# 테스트 실행 명령어
npx hardhat test
# 또는 (Foundry 사용 시)
forge test
