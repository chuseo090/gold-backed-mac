G-MAC (Gold-Backed MyAwesomeCoin) Core Contract 🌟

🌟 프로젝트 개요 (Overview)

G-MAC은 이더리움 기반의 담보형 스테이블 토큰 프로토콜입니다. 저희는 **MyAwesomeCoin (MAC)**을 담보(Collateral)로 활용하여 150% 초과 담보 비율로 G-MAC 토큰을 발행하고 소각합니다. 이는 사용자에게 금 기반 자산에 대한 탈중앙화된 접근성을 제공하는 것을 목표로 합니다.

토큰 이름: Gold-Backed MyAwesomeCoin (G-MAC)

토큰 심볼: G-MAC

표준: ERC-20 (업그레이드 가능 UUPS 패턴)

담보 자산: MyAwesomeCoin (MAC Token)

⚙️ 핵심 메커니즘 (Core Mechanism) - V3 (CertiK Final Version)

G-MAC의 핵심 로직은 GoldBackedMAC_V3.sol 계약에 구현되어 있으며, 주요 기능은 다음과 같습니다.

기능

설명

담보 자산 처리

mint(uint256 amount)

사용자가 MAC 토큰을 예치하고 G-MAC 토큰을 발행합니다.

사용자가 제공한 MAC 토큰을 계약 주소로 전송 및 잠금.

redeem(uint256 amount)

사용자가 G-MAC 토큰을 소각하고 잠겨있던 MAC 담보를 회수합니다.

계약에 잠겨있는 MAC 토큰을 사용자에게 반환.

담보 비율 및 안정화 로직 (V3)

Final Ratio: 현재 $\text{COLLATERAL_RATIO}$는 **1.5:1 (150% 초과 담보)**로 설정되어 있습니다. (1.5 MAC 당 1 G-MAC 발행). 이 초과 담보 로직은 CertiK 감사를 통해 최종 확정되었습니다.

🛡️ 보안 및 감사 상태 (Security and Audit Status) - 감사 완료!

G-MAC 팀은 보안을 최우선으로 생각하며, 최종 코드는 전문 보안 감사를 성공적으로 완료했습니다.

감사 기관: CertiK

코드 상태: CertiK Final Version (GoldBackedMAC_V3.sol)

감사 결과: 모든 치명적 및 주요 지적 사항(Major/Critical Findings)이 수정되었으며, 특히 150% 초과 담보 로직과 업그레이드 패턴이 최종적으로 구현되었습니다.

감사 보고서: 최종 보고서 발행 절차 진행 중이며, 완료되는 대로 이 저장소에 게시될 예정입니다.

🔗 계약 및 투명성 정보 (Contract & Transparency Details)

1. 코어 컨트랙트 정보

항목

값

용도 (투자자 설명)

G-MAC 토큰 주소 (ERC-20)

0xa97f5af62e5e227765e5eccbba7c3ade688342b6

사용자가 거래하는 G-MAC 스테이블 토큰의 공식 주소입니다.

Proxy/Logic 컨트랙트 주소 (V3)

0xcd014ea2f6bb4d008a9f2fce571a8d4866565a80

담보 관리 및 발행 로직이 구현된 컨트랙트 주소입니다.

사용된 Solidity 버전

^0.8.30

-

사용된 라이브러리

OpenZeppelin (Context, Ownable, IERC20, UUPSUpgradeable)

업그레이드 가능한 ERC-20 표준 구현에 사용되었습니다.

2. 팀 지분 락업 (Vesting) 정보 - VC 표준

G-MAC 팀은 VC 표준에 따라 장기적인 헌신을 약속하며, 모든 팀 지분을 투명하게 락업했습니다.
| 구분 | 주소/값 | 용도 (투자자 설명) |
| :--- | :--- | :--- |
| Vesting 계약 주소 (금고) | 0xBEEAfc6388D6BdF53efe53BCF01127A4eba4a027 | 4년 락업 금고의 공식 주소. (소스 코드 검증 완료됨) |
| G-MAC 토큰 주소 | 0xa97f5af62e5e227765e5eccbba7c3ade688342b6 | 락업된 G-MAC 토큰의 주소. |
| Depositor/Beneficiary | 0xe6B2591d564d41d40d61010528D5555cEd391358 | 락업을 실행한 팀 지갑 주소. (투명성 증명) |
| 락업된 수량 | 100,000 G-MAC | 총 $\mathbf{10}$만 G-MAC이 락업됨. |
| Vesting 스케줄 | 1년 Cliff (절벽 기간) 후 $\mathbf{4}$년 Linear Vesting (선형 분배) | 총 $\mathbf{5}$년간의 의무 기간을 통한 장기 프로젝트 헌신 증명. |

🛠️ 빌드 및 테스트 (Build and Test)

필수 환경 (Prerequisites)

Node.js (LTS 버전 권장)

Yarn 또는 npm

Hardhat 또는 Foundry (개발 환경에 맞춰 명시)

설치 및 컴파일

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
