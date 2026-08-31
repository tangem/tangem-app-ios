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
/// The balance endpoint carries a symbol and a contract address only, so the decimals and the coin id
/// come from `TangemPayUtilities`. The canonical USDC entry maps to the hardcoded item instead — the
/// Pay screen tracks pending swaps by that exact item, derivation path and all.
struct TangemPayAccountTokensResolver {
    func resolve(networks: [TangemPayBalance.Network]) -> [TangemPayAccountToken] {
        Self.makeEntries(from: networks).map { entry in
            TangemPayAccountToken(
                tokenItem: canonicalTokenItem(for: entry) ?? tokenItem(for: entry),
                depositAddress: entry.depositAddress,
                availableForWithdrawal: entry.availableForWithdrawal,
                chainId: entry.chainId
            )
        }
    }
}

// MARK: - Account networks

extension TangemPayAccountTokensResolver {
    struct Entry: Equatable {
        let blockchain: Blockchain
        let symbol: String
        let contractAddress: String
        let depositAddress: String
        let availableForWithdrawal: Decimal?
        let chainId: Int?
    }

    /// Only fully operational networks: issued, with a deposit address, on a supported blockchain.
    /// The swap flow picks destinations automatically, so mid-issuance networks stay out until `enabled`.
    static func makeEntries(from networks: [TangemPayBalance.Network]) -> [Entry] {
        networks.flatMap { network -> [Entry] in
            guard
                network.status == .enabled,
                let depositAddress = network.depositAddress?.nilIfEmpty,
                let blockchain = TangemPayUtilities.blockchain(for: network)
            else {
                return []
            }

            return network.tokens.map { token in
                Entry(
                    blockchain: blockchain,
                    symbol: token.token,
                    contractAddress: token.tokenContractAddress,
                    depositAddress: depositAddress,
                    availableForWithdrawal: token.availableForWithdrawal,
                    chainId: network.chainId
                )
            }
        }
    }
}

// MARK: - Token items

private extension TangemPayAccountTokensResolver {
    /// A token neither table knows keeps a placeholder icon and no rate, which beats hiding
    /// one the account holds funds on.
    func tokenItem(for entry: Entry) -> TokenItem {
        .token(
            Token(
                name: entry.symbol,
                symbol: entry.symbol,
                // Express compares contracts verbatim; the wallet's own tokens carry the catalog's
                // lowercase form, and a checksummed one would read as a different token.
                contractAddress: entry.contractAddress.lowercased(),
                decimalCount: TangemPayUtilities.tokenDecimalCount(chainId: entry.chainId),
                id: TangemPayUtilities.tokenId(symbol: entry.symbol),
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(entry.blockchain, derivationPath: nil)
        )
    }

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
}
