G-MAC (Gold-Backed MyAwesomeCoin) Core Infrastructure 🌟

🌟 Project Overview

G-MAC is an Ethereum-based collateralized stablecoin protocol. We utilize MyAwesomeCoin (MAC) as collateral to issue and burn G-MAC tokens with a 150% overcollateralization ratio. Our primary mission is to provide decentralized, algorithmic access to gold-backed assets to neutralize systemic financial risks.

Token Name: Gold-Backed MyAwesomeCoin (G-MAC)

Token Symbol: G-MAC

Standard: ERC-20 (Upgradeable UUPS Pattern)

Collateral Asset: MyAwesomeCoin (MAC Token)

⚙️ Core Mechanism - V3 (CertiK Verified)

The core logic of G-MAC is implemented in the GoldBackedMAC_V3.sol contract, ensuring stability through mathematical parity.

Function

Description

Implementation Detail

mint(uint256 amount)

User deposits MAC tokens to issue G-MAC.

Transfers and locks MAC to the vault at 1.5:1 ratio.

redeem(uint256 amount)

User burns G-MAC to redeem locked MAC.

Executes burn and releases the proportional collateral.

Collateral Ratio and Stability Logic

Final Ratio: The $\text{COLLATERAL\_RATIO}$ is fixed at 1.5:1 (150% Overcollateralized).

Verification: This logic has been audited by CertiK, ensuring no unauthorized minting or collateral leakage is possible.

🛡️ Security and Audit Status

The G-MAC protocol follows the highest institutional security standards.

Audit Firm: CertiK

Code Status: CertiK Final Production Version (GoldBackedMAC_V3.sol)

Audit Result: All Major/Critical Findings Resolved. Specifically, the 150% overcollateralization logic and UUPS upgrade pattern are confirmed secure.

On-Chain Proof: Verified Source Code is available on Ethereum Sepolia.

🔗 Contract and Transparency Details

1. Official Smart Contract Coordinates

Item

Address (Sepolia)

Implication (Investor Note)

Logic Address (V3)

0x7b1C46CA6C5C36F13910AD2eb62622934B8b5eE8

The core algorithmic engine (Verified).

Proxy Address

0xA97f5af62e5e227765e5ECCbBa7C3Ade688342B6

The official entry point for institutional liquidity.

Solidity Version

^0.8.30

Utilizing the latest security patches.

Library

OpenZeppelin

Standardized UUPS Upgradeable Framework.

2. Strategic Asset Reserve (Vesting) - VC Hard Standard

To ensure the long-term integrity of the $3,000T risk mitigation mission, the team's reserve is subject to a strict non-negotiable lockup.

Item

Value / Protocol

Implication

Vesting Vault

0xBEEAfc6388D6BdF53efe53BCF01127A4eba4a027

The official decentralized time-lock contract.

Reserve Amount

90,000,000 G-MAC

90% of Total Supply is reserved for systemic balancing.

Lockup Schedule

4-Year Hard Lockup

Zero Liquidity Access for 48 months. (No linear release).

Commitment

Absolute Hard Lock

Physical inaccessibility ensures 100% alignment with long-term holders.

🛠️ Developer Environment

Installation

git clone [https://github.com/chuseo090/gold-backed-mac](https://github.com/chuseo090/gold-backed-mac)
cd gold-backed-mac
yarn install


Compilation & Test

npx hardhat compile
npx hardhat test
