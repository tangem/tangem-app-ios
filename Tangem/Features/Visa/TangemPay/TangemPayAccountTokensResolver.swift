//
//  TangemPayAccountTokensResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemPay

/// Turns the payment account's per-network tokens into `TangemPayAccountToken`s.
///
/// The balance endpoint carries a symbol and a contract address but no decimals, so the token items are
/// looked up in the coins API. A token that can't be resolved there is dropped, except the canonical
/// USDC one: guessing decimals would silently misprice every quote made against it.
struct TangemPayAccountTokensResolver {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    func resolve(networks: [TangemPayBalance.Network]) async -> [TangemPayAccountToken] {
        let entries = Self.makeEntries(from: networks)

        guard !entries.isEmpty else {
            return []
        }

        let tokenItems = await loadTokenItems(
            blockchains: Set(entries.map(\.blockchain)),
            contractAddresses: entries.map(\.contractAddress)
        )

        return entries.compactMap { entry -> TangemPayAccountToken? in
            guard let tokenItem = tokenItems[entry.tokenItemKey] ?? canonicalTokenItem(for: entry) else {
                return nil
            }

            return TangemPayAccountToken(
                tokenItem: tokenItem,
                depositAddress: entry.depositAddress,
                availableForWithdrawal: entry.availableForWithdrawal
            )
        }
    }
}

// MARK: - Account networks

extension TangemPayAccountTokensResolver {
    struct Entry: Equatable {
        let blockchain: Blockchain
        let contractAddress: String
        let depositAddress: String
        let availableForWithdrawal: Decimal?

        fileprivate var tokenItemKey: TokenItemKey {
            TokenItemKey(networkId: blockchain.networkId, contractAddress: contractAddress)
        }
    }

    /// Only fully operational networks: issued, with a deposit address, on a supported blockchain.
    /// The swap flow picks destinations automatically, so mid-issuance networks stay out until `enabled`.
    static func makeEntries(from networks: [TangemPayBalance.Network]) -> [Entry] {
        networks.flatMap { network -> [Entry] in
            guard
                network.status == .enabled,
                let depositAddress = network.depositAddress?.nilIfEmpty,
                let blockchain = TangemPayUtilities.blockchain(name: network.name, isTestnet: network.isTestnet)
            else {
                return []
            }

            return network.tokens.map { token in
                Entry(
                    blockchain: blockchain,
                    contractAddress: token.tokenContractAddress,
                    depositAddress: depositAddress,
                    availableForWithdrawal: token.availableForWithdrawal
                )
            }
        }
    }
}

// MARK: - Coins API

private extension TangemPayAccountTokensResolver {
    /// Contract addresses come from the BFF in an arbitrary checksum casing, so the key is lowercased.
    struct TokenItemKey: Hashable {
        let networkId: String
        let contractAddress: String

        init(networkId: String, contractAddress: String) {
            self.networkId = networkId.lowercased()
            self.contractAddress = contractAddress.lowercased()
        }
    }

    /// The hardcoded token needs no lookup, so its entry survives a coins API failure.
    func canonicalTokenItem(for entry: Entry) -> TokenItem? {
        let canonical = TangemPayUtilities.usdcTokenItem

        guard
            entry.blockchain == canonical.blockchain,
            entry.contractAddress.lowercased() == canonical.contractAddress?.lowercased()
        else {
            return nil
        }

        return canonical
    }

    func loadTokenItems(blockchains: Set<Blockchain>, contractAddresses: [String]) async -> [TokenItemKey: TokenItem] {
        let request = CoinsList.Request(
            supportedBlockchains: blockchains,
            contractAddresses: contractAddresses.unique()
        )

        guard let response = try? await tangemApiService.loadCoins(requestModel: request) else {
            return [:]
        }

        let coinModels = CoinsResponseMapper(supportedBlockchains: blockchains).mapToCoinModels(response)
        let tokenItems = coinModels.flatMap(\.items).map(\.tokenItem)

        let pairs = tokenItems.compactMap { tokenItem -> (TokenItemKey, TokenItem)? in
            guard let contractAddress = tokenItem.contractAddress else {
                return nil
            }

            let key = TokenItemKey(networkId: tokenItem.networkId, contractAddress: contractAddress)
            return (key, tokenItem)
        }

        return Dictionary(pairs, uniquingKeysWith: { first, _ in first })
    }
}
