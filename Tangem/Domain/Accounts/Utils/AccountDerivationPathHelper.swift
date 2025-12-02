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
        let nodesCount = derivationPath.nodes.count
        let nodeIndex: Int

        switch blockchain {
        case .quai,
             .tezos:
            // Some non-UTXO and non-EVM blockchains (like Tezos, Quai and so on) require special handling
            nodeIndex = Constants.accountNodeIndex
        case _ where blockchain.isEvm:
            nodeIndex = Constants.addressIndexNodeIndex
        default:
            nodeIndex = Constants.accountNodeIndex
        }

        guard nodesCount > nodeIndex else {
            let message = "Unexpected derivation path nodes count: \(nodesCount) for blockchain: \(blockchain.displayName)"

            AppLogger.warning(message)
            assertionFailure(message)

            return max(0, nodesCount - 1)
        }

        return nodeIndex
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
        /// 3rd node `account` (m / purpose' / coin_type' / account' / change / address_index)
        static let accountNodeIndex = 2
        /// 5th node `address_index` (m / purpose' / coin_type' / account' / change / address_index)
        static let addressIndexNodeIndex = 4
    }
}
