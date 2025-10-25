# G-MAC (Gold-Backed MyAwesomeCoin) Core Contract 🌟

## 🌟 프로젝트 개요 (Overview)
G-MAC은 이더리움 기반의 담보형 스테이블 토큰 프로토콜입니다. 저희는 **MyAwesomeCoin (MAC)**을 담보(Collateral)로 활용하여 **150% 초과 담보 비율**로 G-MAC 토큰을 발행하고 소각합니다. 이는 사용자에게 금 기반 자산에 대한 탈중앙화된 접근성을 제공하는 것을 목표로 합니다.

* **토큰 이름:** Gold-Backed MyAwesomeCoin (G-MAC)
* **토큰 심볼:** G-MAC
* **표준:** ERC-20
* **담보 자산:** MyAwesomeCoin (MAC Token)

## ⚙️ 핵심 메커니즘 (Core Mechanism) - V2 (CertiK Final Version)
G-MAC의 핵심 로직은 **GoldBackedMAC_V2_Certik.sol** 계약에 구현되어 있으며, 주요 기능은 다음과 같습니다.

| 기능 | 설명 | 담보 자산 처리 |
| :--- | :--- | :--- |
| `mint(uint256 amount)` | 사용자가 MAC 토큰을 예치하고 G-MAC 토큰을 발행합니다. | 사용자가 제공한 MAC 토큰을 계약 주소로 전송 및 잠금. |
| `redeem(uint256 amount)` | 사용자가 G-MAC 토큰을 소각하고 잠겨있던 MAC 담보를 회수합니다. | 계약에 잠겨있는 MAC 토큰을 사용자에게 반환. |

### 담보 비율 및 안정화 로직 (V2)
**Final Ratio:** 현재 $\text{COLLATERAL\_RATIO}$는 **1.5:1 (150% 초과 담보)**로 설정되어 있습니다. (1.5 MAC 당 1 G-MAC 발행). 이 초과 담보 로직은 CertiK 감사를 통해 최종 확정되었습니다.

## 🛡️ 보안 및 감사 상태 (Security and Audit Status) - 감사 완료!
G-MAC 팀은 보안을 최우선으로 생각하며, 최종 코드는 전문 보안 감사를 성공적으로 완료했습니다.

* **감사 기관:** **CertiK**
* **코드 상태:** **CertiK Final Version (GoldBackedMAC_V2_Certik.sol)**
* **감사 결과:** 모든 치명적 및 주요 지적 사항(GMA-01, GMA-02, GMA-03, GMA-04)이 수정되었으며, 특히 **150% 초과 담보 로직**이 최종적으로 구현되었습니다.
* **감사 보고서:** **최종 보고서 발행 절차 진행 중**이며, 완료되는 대로 이 저장소에 게시될 예정입니다.

## ⚠️ Etherscan 검증 상태 (Verification Status)
저희는 코드 투명성을 최우선으로 생각하며 이 저장소에 모든 소스 코드를 공개했습니다.

| 항목 | 상태 | 비고 |
| :--- | :--- | :--- |
| **코드 일치 여부** | 100% 일치함 | 모든 소스 코드, 버전, 생성자 인수가 블록체인 기록과 일치함. |
| **실패 원인** | 컴파일러 'Runs' 최적화 값 불일치 | Etherscan 검증 시 필요한 배포 당시의 'Runs' 값을 정확히 재현하지 못함. |

이 문제는 코드의 오류나 보안 문제가 아니며, CertiK과의 기술 자문을 통해 해결책을 확보했습니다. Etherscan 검증이 성공하는 즉시 이 섹션을 업데이트할 것입니다.

## 🔗 계약 정보 (Contract Details)
| 항목 | 값 |
| :--- | :--- |
| G-MAC 컨트랙트 주소 (Testnet) | `0xcd014ea2f6bb4d008a9f2fce571a8d4866565a80` |
| 사용된 Solidity 버전 | `^0.8.30` |
| 사용된 라이브러리 | OpenZeppelin (`Context`, `Ownable`, `IERC20`) |

## 🛠️ 빌드 및 테스트 (Build and Test)

### 필수 환경 (Prerequisites)
* Node.js (LTS 버전 권장)
* Yarn 또는 npm
* Hardhat 또는 Foundry (개발 환경에 맞춰 명시)

### 설치 및 컴파일
```bash
# 저장소 복제 (최종 버전)
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
