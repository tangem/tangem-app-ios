//
//  WalletConnectDAppBlockchainsAvailabilityResult.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

struct WalletConnectDAppBlockchainsAvailabilityResult {
    let unavailableRequiredBlockchains: [Blockchain]
    let availableBlockchains: [AvailableBlockchain]
    let notAddedBlockchains: [Blockchain]

    func retrieveSelectedBlockchains() -> [WalletConnectDAppBlockchain] {
        availableBlockchains
            .compactMap { availableBlockchain in
                switch availableBlockchain {
                case .required(let blockchain):
                    return WalletConnectDAppBlockchain(blockchain: blockchain, isRequired: true)
                case .optional(let optionalBlockchain) where optionalBlockchain.isSelected:
                    return WalletConnectDAppBlockchain(blockchain: optionalBlockchain.blockchain, isRequired: false)
                case .optional:
                    return nil
                }
            }
    }
}

extension WalletConnectDAppBlockchainsAvailabilityResult {
    struct OptionalBlockchain {
        let blockchain: Blockchain
        let isSelected: Bool
    }

    enum AvailableBlockchain {
        case required(Blockchain)
        case optional(OptionalBlockchain)

        var blockchain: Blockchain {
            switch self {
            case .required(let blockchain):
                blockchain
            case .optional(let optionalBlockchain):
                optionalBlockchain.blockchain
            }
        }

        var isSelected: Bool {
            switch self {
            case .required:
                true
            case .optional(let optionalBlockchain):
                optionalBlockchain.isSelected
            }
        }
    }
}
