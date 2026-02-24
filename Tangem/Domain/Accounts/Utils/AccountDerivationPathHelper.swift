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

struct AccountDerivationPathHelper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func extractAccountDerivationNode(from derivationPath: DerivationPath) throws(Error) -> DerivationNode {
        guard areAccountsAvailableForBlockchain() else {
            let displayName = blockchain.displayName
            AppLogger.warning("Attempting to extract account derivation node for unsupported blockchain: \(displayName)")
            throw .accountsUnavailableForBlockchain(displayName)
        }

        let accountDerivationNodeIndex = try accountDerivationNodeIndex(for: derivationPath)

        return derivationPath.nodes[accountDerivationNodeIndex]
    }

    func makeDerivationPath(from derivationPath: DerivationPath, forAccountWithIndex accountIndex: Int) throws(Error) -> DerivationPath {
        let rawAccountIndex = UInt32(accountIndex)
        let accountDerivationNodeIndex = try accountDerivationNodeIndex(for: derivationPath)
        var nodes = derivationPath.nodes

        nodes[accountDerivationNodeIndex] = nodes[accountDerivationNodeIndex].withRawIndex(rawAccountIndex)

        return DerivationPath(nodes: nodes)
    }

    private func accountDerivationNodeIndex(for derivationPath: DerivationPath) throws(Error) -> Int {
        let nodeIndex: Int

        switch blockchain {
        case .quai,
             .tezos:
            // Some non-UTXO and non-EVM blockchains (like Tezos, Quai and so on) require special handling
            nodeIndex = Constants.accountNodeIndex
        case _ where blockchain.isEvm:
            nodeIndex = try evmAccountDerivationNodeIndex(for: derivationPath)
        default:
            nodeIndex = Constants.accountNodeIndex
        }

        let actualNodesCount = derivationPath.nodes.count
        let requiredNodesCount = nodeIndex + 1
        guard actualNodesCount >= requiredNodesCount else {
            throw .insufficientNodes(required: requiredNodesCount, actual: actualNodesCount, blockchain: blockchain.displayName)
        }

        return nodeIndex
    }

    /// See Accounts-REQ-App-006 for details.
    private func evmAccountDerivationNodeIndex(for derivationPath: DerivationPath) throws(Error) -> Int {
        guard
            let purposeNode = derivationPath.nodes[safe: Constants.purposeNodeIndex],
            let coinTypeNode = derivationPath.nodes[safe: Constants.coinTypeNodeIndex]
        else {
            let actualNodesCount = derivationPath.nodes.count
            let requiredNodesCount = Constants.coinTypeNodeIndex + 1
            throw .insufficientNodes(required: requiredNodesCount, actual: actualNodesCount, blockchain: blockchain.displayName)
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
             .monad,
             .berachain,
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

// MARK: - Error

extension AccountDerivationPathHelper {
    enum Error: Swift.Error, LocalizedError {
        case insufficientNodes(required: Int, actual: Int, blockchain: String)
        case accountsUnavailableForBlockchain(_ blockchain: String)

        var errorDescription: String? {
            switch self {
            case .insufficientNodes(let required, let actual, let blockchain):
                return "Derivation path for \(blockchain) has insufficient nodes: expected at least \(required), got \(actual)"
            case .accountsUnavailableForBlockchain(let blockchain):
                return "Blockchain \(blockchain) does not support custom derivation paths and accounts."
            }
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
