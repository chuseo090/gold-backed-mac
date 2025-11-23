G-MAC (Gold-Backed MyAwesomeCoin) Core Contract 🌟

🌟 Project Overview

G-MAC is an Ethereum-based collateralized stablecoin protocol. We utilize MyAwesomeCoin (MAC) as collateral to issue and burn G-MAC tokens with a 150% overcollateralization ratio. Our goal is to provide decentralized access to gold-backed assets.

Token Name: Gold-Backed MyAwesomeCoin (G-MAC)

Token Symbol: G-MAC

Standard: ERC-20 (Upgradeable UUPS Pattern)

Collateral Asset: MyAwesomeCoin (MAC Token)

⚙️ Core Mechanism - V3 (CertiK Final Version)

The core logic of G-MAC is implemented in the GoldBackedMAC_V3.sol contract.

Function

Description

Collateral Asset Handling

mint(uint256 amount)

User deposits MAC tokens to issue G-MAC tokens.

Transfers and locks user-provided MAC tokens to the contract address.

redeem(uint256 amount)

User burns G-MAC tokens to redeem locked MAC collateral.

Returns locked MAC tokens from the contract to the user.

Collateral Ratio and Stability Logic (V3)

Final Ratio: The $\text{COLLATERAL\_RATIO}$ is set to 1.5:1 (150% Overcollateralized). (1.5 MAC issues 1 G-MAC). This overcollateralization logic has been finally confirmed through the CertiK audit.

🛡️ Security and Audit Status - Audit Completed!

The G-MAC team prioritizes security, and the final code has successfully completed a professional security audit.

Audit Firm: CertiK

Code Status: CertiK Final Version (GoldBackedMAC_V3.sol)

Audit Result: All Major/Critical Findings have been resolved, and specifically, the 150% overcollateralization logic and upgrade pattern have been successfully implemented.

Audit Report: Final report issuance is in progress and will be posted to this repository upon completion.

🔗 Contract and Transparency Details

1. Core Contract Information

Item

Value

Implication (Investor Note)

G-MAC Token Address (ERC-20)

0xa97f5af62e5e227765e5eccbba7c3ade688342b6

The official address of the tradable G-MAC stable token.

Proxy/Logic Contract Address (V3)

0xcd014ea2f6bb4d008a9f2fce571a8d4866565a80

The contract where collateral management and issuance logic is implemented.

Solidity Version Used

^0.8.30

-

Used Libraries

OpenZeppelin (Context, Ownable, IERC20, UUPSUpgradeable)

Used to implement the upgradeable ERC-20 standard.

2. Founder Lockup (Vesting) Information - VC Standard

The G-MAC team commits to long-term dedication following VC standards, with all founder tokens transparently locked up.
| Item | Address/Value | Implication (Investor Note) |
| :--- | :--- | :--- |
| Vesting Contract Address (Vault) | 0xBEEAfc6388D6BdF53efe53BCF01127A4eba4a027 | The official address of the 4-year lockup vault. (Source code verified) |
| G-MAC Token Address | 0xa97f5af62e5e227765e5eccbba7c3ade688342b6 | The address of the locked G-MAC tokens. |
| Depositor/Beneficiary | 0xe6B2591d564d41d40d61010528D5555cEd391358 | The team wallet address that executed the lockup. (Proof of transparency) |
| Locked Amount | 100,000 G-MAC | A total of $\mathbf{100,000}$ G-MAC is locked up. |
| Vesting Schedule | 1 year Cliff followed by $\mathbf{4}$ year Linear Vesting | Proof of $\mathbf{5}$ years total commitment (a mandatory VC requirement). |

🛠️ Build and Test

Prerequisites

Node.js (LTS version recommended)

Yarn or npm

Hardhat or Foundry (as defined by your development environment)

Installation and Compilation

# Clone the repository (Final Version)
git clone [https://github.com/chuseo090/gold-backed-mac](https://github.com/chuseo090/gold-backed-mac)
cd gold-backed-mac

# Install dependencies
yarn install 
# OR
npm install

# Compile contracts
npx hardhat compile
# OR (if using Foundry)
forge build

# Run tests
npx hardhat test
# OR (if using Foundry)
forge test
