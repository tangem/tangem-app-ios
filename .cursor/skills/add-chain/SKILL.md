---
name: add-chain
description: This skill adds new chain in the app using chain description and specs.
---

# My Skill

Add new chain into the app using the provided intructions.

## Instructions

- Add the new case in `Blockchain` and wire `isTestnet`, decimals, symbol, chain id, EVM flag, coding/decoding, analytics ids, and wallet assembly.
- Include the chain in `Blockchain+AllCases.swift` compile guard and list.
- Update derivation/address behavior: `DerivationConfigV1/V2/V3`, `AddressTypesConfig`, `AddressServiceFactory`, and `EstimationFeeAddressFactory` as needed. For `DerivationConfigV1` check docs by links for chain and set specific derivation path if needed.
- Configure RPCs and API keys: `TestnetAPINodeInfoProvider`, `QuickNodeAPIResolver`, `BlockchainSdkKeysConfig`, `CommonKeysManager`, and `BlockchainSdkExample/APIListUtils`.
- Add explorer/faucet links via `<Chain>ExternalLinkProvider` and `ExternalLinkProviderFactory`.
- Wire network services in `WalletNetworkServiceFactory` (typically `makeEthereumNetworkService` for EVM chains).
- Update app features: `AccountDerivationPathHelper`, `ReceiveBottomSheetNotificationInputsFactory`, `TransactionParamsBuilder`, `CustomTokenContractAddressConverter`, `NFTChainConverter`, `TransactionHistoryProviderFactory`, and `MoonPayService`.
- Update `SupportedBlockchains`, add only to testable blockchains and testnet blockchains if avilable.
- Add assets and UI mapping: `Modules/TangemAssets/Assets/Tokens.xcassets` and `NetworkImageProvider`.
- Add new source files to `TangemApp.xcodeproj/project.pbxproj`.
- Update/extend tests (e.g. RPC lists or chain mappings) and bump `tangem-app-config` if chain metadata lives there.
- Finish chain add by building the project and fixing compilation errors if appear.