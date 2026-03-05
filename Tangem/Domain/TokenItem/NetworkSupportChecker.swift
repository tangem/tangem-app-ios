//
//  NetworkSupportChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Checks whether a network is supported for a given set of blockchains.
enum NetworkSupportChecker {
    static func isNetworkSupported(
        _ network: NetworkModel,
        in supportedBlockchains: Set<Blockchain>
    ) -> Bool {
        guard let blockchain = supportedBlockchains[network.networkId] else {
            return false
        }

        // Native coins (no contract address or no decimal count) are always supported
        guard let contractAddress = network.contractAddress, network.decimalCount != nil else {
            return true
        }

        // Tokens require blockchain to support token handling
        return SupportedTokensFilter.canHandleToken(contractAddress: contractAddress, blockchain: blockchain)
    }

    /// Checks if any network from the list is supported by any of the user wallet models.
    /// Only multi-currency wallets are considered.
    static func hasAnySupportedNetwork(
        networks: [NetworkModel],
        userWalletModels: [UserWalletModel]
    ) -> Bool {
        guard networks.isNotEmpty else {
            return false
        }

        let multiCurrencyModels = userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }

        for model in multiCurrencyModels {
            for network in networks {
                if isNetworkSupported(network, in: model.config.supportedBlockchains) {
                    return true
                }
            }
        }

        return false
    }
}
