//
//  AccountDerivationPathHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
struct AccountDerivationPathHelper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func extractAccountDerivationNode(from derivationPath: DerivationPath?) -> DerivationNode? {
        guard let derivationPath else {
            return nil
        }

        guard areAccountsAvailableForBlockchain() else {
            AppLogger.warning("Attempting to extract account derivation node for unsupported blockchain: \(blockchain.displayName)")
            return nil
        }

        let accountDerivationNodeIndex = accountDerivationNodeIndex(for: derivationPath)

        return derivationPath.nodes[accountDerivationNodeIndex]
    }

    func makeDerivationPath(from derivationPath: DerivationPath, forAccountWithIndex accountIndex: Int) -> DerivationPath {
        let rawAccountIndex = UInt32(accountIndex)
        let accountDerivationNodeIndex = accountDerivationNodeIndex(for: derivationPath)
        var nodes = derivationPath.nodes

        nodes[accountDerivationNodeIndex] = nodes[accountDerivationNodeIndex].withRawIndex(rawAccountIndex)

        return DerivationPath(nodes: nodes)
    }

    private func accountDerivationNodeIndex(for derivationPath: DerivationPath) -> Int {
        let nodes = derivationPath.nodes

        switch nodes.count {
        case _ where blockchain.isQuai,
             _ where blockchain.isTezos:
            // Some non-UTXO blockchains (like Tezos, Quai and so on) require special handling
            return Constants.nonUTXONonStandardDerivationNodeIndex
        case 5 where blockchain.isUTXO:
            return Constants.utxoDerivationNodeIndex
        case 3 where !blockchain.isUTXO,
             5 where !blockchain.isUTXO:
            // For non-UTXO blockchains we use the last node as account node (either 3rd or 5th)
            return nodes.count - 1
        default:
            // Currently, there are no blockchains with other derivation path nodes count
            // Such blockchains should be handled here explicitly
            assertionFailure("Unexpected derivation path nodes count: \(nodes.count) for blockchain: \(blockchain.displayName)")
            return max(0, nodes.count - 1)
        }
    }

    func areAccountsAvailableForBlockchain() -> Bool {
        // Did you get a compilation error here? If so, consult with analytics team to find out
        // whether a newly added blockchain supports custom derivations and accounts
        switch blockchain {
        case .bitcoin,
             .litecoin,
             .stellar,
             .ethereum,
             .ethereumPoW,
             .disChain,
             .ethereumClassic,
             .rsk,
             .bitcoinCash,
             .binance,
             .cardano,
             .xrp,
             .ducatus,
             .tezos,
             .dogecoin,
             .bsc,
             .polygon,
             .avalanche,
             .solana,
             .fantom,
             .polkadot,
             .kusama,
             .azero,
             .tron,
             .arbitrum,
             .dash,
             .gnosis,
             .optimism,
             .ton,
             .kava,
             .kaspa,
             .ravencoin,
             .cosmos,
             .terraV1,
             .terraV2,
             .cronos,
             .telos,
             .octa,
             .near,
             .decimal,
             .veChain,
             .xdc,
             .algorand,
             .shibarium,
             .aptos,
             .hedera,
             .areon,
             .playa3ullGames,
             .pulsechain,
             .aurora,
             .manta,
             .zkSync,
             .moonbeam,
             .polygonZkEVM,
             .moonriver,
             .mantle,
             .flare,
             .taraxa,
             .radiant,
             .base,
             .joystream,
             .bittensor,
             .koinos,
             .internetComputer,
             .cyber,
             .blast,
             .sui,
             .filecoin,
             .sei,
             .energyWebEVM,
             .energyWebX,
             .core,
             .canxium,
             .casper,
             .chiliz,
             .xodex,
             .clore,
             .fact0rn,
             .odysseyChain,
             .bitrock,
             .apeChain,
             .sonic,
             .alephium,
             .vanar,
             .zkLinkNova,
             .pepecoin,
             .hyperliquidEVM,
             .quai,
             .scroll,
             .linea,
             .arbitrumNova,
             .plasma:
            return true
        case .chia:
            return false
        }
    }
}

// MARK: - Static Helpers

extension AccountDerivationPathHelper {
    /// Filters a set of blockchains to include only those that support multiple accounts.
    /// Some blockchains don't support custom derivation paths and multiple accounts.
    /// - Parameter blockchains: The set of blockchains to filter
    /// - Returns: A set of blockchains that support multiple accounts
    static func filterBlockchainsSupportingAccounts(_ blockchains: Set<Blockchain>) -> Set<Blockchain> {
        blockchains.filter { blockchain in
            AccountDerivationPathHelper(blockchain: blockchain).areAccountsAvailableForBlockchain()
        }
    }

    /// Checks if a blockchain with the given networkId supports multiple accounts.
    /// - Parameters:
    ///   - networkId: The network identifier
    ///   - supportedBlockchains: The set of supported blockchains to search in
    /// - Returns: `true` if the blockchain exists and supports accounts, `false` otherwise
    static func supportsAccounts(networkId: String, in supportedBlockchains: Set<Blockchain>) -> Bool {
        guard let blockchain = supportedBlockchains[networkId] else {
            return false
        }
        return AccountDerivationPathHelper(blockchain: blockchain).areAccountsAvailableForBlockchain()
    }
}

// MARK: - Constants

private extension AccountDerivationPathHelper {
    enum Constants {
        /// 3rd node for UTXO blockchains (m / purpose' / coin_type' / account' / change / address_index)
        static let utxoDerivationNodeIndex = 2
        /// 3rd node for some non-UTXO blockchains (like Tezos, Quai and so on) (m / purpose' / coin_type' / account' / unspecified)
        static let nonUTXONonStandardDerivationNodeIndex = 2
    }
}

// MARK: - Convenience extensions

private extension Blockchain {
    var isTezos: Bool {
        if case .tezos = self {
            return true
        }
        return false
    }

    var isQuai: Bool {
        if case .quai = self {
            return true
        }
        return false
    }
}
