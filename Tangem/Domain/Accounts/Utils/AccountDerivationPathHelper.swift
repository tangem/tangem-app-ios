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
            nodeIndex = evmAccountDerivationNodeIndex(for: derivationPath)
        default:
            nodeIndex = Constants.accountNodeIndex
        }

        guard nodesCount > nodeIndex else {
            let message = "Unexpected derivation path nodes count: \(nodesCount) for the blockchain: \(blockchain.displayName)"

            AppLogger.warning(message)
            assertionFailure(message)

            return max(0, nodesCount - 1)
        }

        return nodeIndex
    }

    /// See Accounts-REQ-App-006 for details.
    private func evmAccountDerivationNodeIndex(for derivationPath: DerivationPath) -> Int {
        guard
            let purposeNode = derivationPath.nodes[safe: Constants.purposeNodeIndex],
            let coinTypeNode = derivationPath.nodes[safe: Constants.coinTypeNodeIndex]
        else {
            let message = "No `purpose` and/or `coin_type` node in the derivation path for the blockchain: \(blockchain.displayName), likely malformed derivation path"

            AppLogger.warning(message)
            assertionFailure(message)

            return Constants.addressIndexNodeIndex
        }

        return purposeNode.rawIndex == Constants.evmPurposeNodeValue && coinTypeNode.rawIndex == Constants.evmCoinTypeNodeValue
            ? Constants.addressIndexNodeIndex
            : Constants.accountNodeIndex
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
}

// MARK: - Constants

private extension AccountDerivationPathHelper {
    enum Constants {
        /// 1st node `purpose` (m / purpose' / coin_type' / account' / change / address_index)
        static let purposeNodeIndex = 0
        /// 2nd node `coin_type` (m / purpose' / coin_type' / account' / change / address_index)
        static let coinTypeNodeIndex = 1
        /// 3rd node `account` (m / purpose' / coin_type' / account' / change / address_index)
        static let accountNodeIndex = 2
        /// 5th node `address_index` (m / purpose' / coin_type' / account' / change / address_index)
        static let addressIndexNodeIndex = 4
        /// See Accounts-REQ-App-006 for details.
        static let evmPurposeNodeValue = 44
        /// See Accounts-REQ-App-006 for details.
        static let evmCoinTypeNodeValue = 60
    }
}
