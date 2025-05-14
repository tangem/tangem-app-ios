//
//  WCUtils.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import ReownWalletKit

struct WCUtils {
    func extractUnsupportedBlockchainNames(from namespaces: [String: ProposalNamespace]) -> [String] {
        namespaces.reduce([String]()) { partialResult, namespace in
            guard let blockchains = namespace.value.chains else { return partialResult }

            let unsupportedBlockchains = blockchains.compactMap { blockchain in
                let blockсhainMeta = WCUtils.makeBlockchain(from: blockchain)

                if WCSupportedNamespaces(rawValue: namespace.key) != nil {
                    return blockсhainMeta == nil ? blockchain.absoluteString : nil
                } else {
                    return blockсhainMeta?.displayName ?? namespace.key.capitalizingFirstLetter()
                }
            }

            return partialResult + unsupportedBlockchains
        }
    }

    func allChainsSupported(in namespaces: [String: ProposalNamespace]) -> Bool {
        for (namespace, proposals) in namespaces {
            guard WCSupportedNamespaces(rawValue: namespace) != nil else { return false }

            let blockchains = proposals.chains?.compactMap(WCUtils.makeBlockchain(from:))

            if blockchains?.count != proposals.chains?.count {
                return false
            }
        }

        return true
    }
}

// MARK: - Create session namespaces

extension WCUtils {
    func createSessionRequest(
        proposal: Session.Proposal,
        selectedWalletModelProvider: WalletConnectWalletModelProvider,
        selectedUserWalletModelId: String,
        selectedOptionalNetworks: [BlockchainNetwork] = []
    ) throws -> (SessionNamespace: [String: SessionNamespace], requestData: [WCConnectionRequestData]) {
        let builder = WCSessionNamespacesBuilder()
        let chains = Set(proposal.namespaceChains)

        let requestData: [WCConnectionRequestData] = chains.compactMap { wcBlockchain -> WCConnectionRequestData? in
            builder.makeConnectionRequestData(
                from: wcBlockchain,
                and: proposal,
                selectedOptionalBlockchains: selectedOptionalNetworks,
                selectedWalletModelProvider: selectedWalletModelProvider
            )
        }
        try checkMissingBlockchains(builder.missingBlockchains)

        try checkUnsupportedEVMBlockchains(builder.unsupportedEVMBlockchains)

        let sessionNamespaces = try AutoNamespaces.build(
            sessionProposal: proposal,
            chains: Array(builder.supportedChains),
            methods: proposal.namespaceMethods,
            events: proposal.namespaceEvents,
            accounts: requestData.compactMap(\.accounts).reduce([], +)
        )

        return (sessionNamespaces, requestData)
    }

    private func checkMissingBlockchains(_ blockchains: [String]) throws {
        guard blockchains.isEmpty else {
            throw WalletConnectV2Error.missingBlockchains(blockchains)
        }
    }

    private func checkUnsupportedEVMBlockchains(_ blockchains: [String]) throws {
        guard blockchains.isEmpty else {
            throw WalletConnectV2Error.unsupportedBlockchains(blockchains)
        }
    }
}

// MARK: - Create Tangem blockchain

extension WCUtils {
    static func makeBlockchainMeta(from wcBlockchain: WalletConnectUtils.Blockchain) -> BlockchainMeta? {
        guard WCUtils.WCSupportedNamespaces(rawValue: wcBlockchain.namespace) != nil else {
            return nil
        }

        let blockchains = SupportedBlockchains.all
        let wcChainId = wcBlockchain.reference
        let blockchain = blockchains.first { $0.wcChainID?.contains(wcChainId) ?? false }

        return .init(from: blockchain)
    }

    static func makeBlockchain(from wcBlockchain: WalletConnectUtils.Blockchain) -> BlockchainSdk.Blockchain? {
        guard WCUtils.WCSupportedNamespaces(rawValue: wcBlockchain.namespace) != nil else {
            return nil
        }

        let blockchains = SupportedBlockchains.all
        let wcChainId = wcBlockchain.reference
        let blockchain = blockchains.first { $0.wcChainID?.contains(wcChainId) ?? false }

        return blockchain
    }
}

// MARK: - Blockchain names from namespaces

extension WCUtils {
    func getBlockchainNamesFromNamespaces(
        _ namespaces: [String: SessionNamespace],
        walletModelProvider: WalletConnectWalletModelProvider
    ) -> [String] {
        mapBlockchainNetworks(from: namespaces, walletModelProvider: walletModelProvider).map(\.blockchain.displayName)
    }

    func createBlockchainNetwork(
        from wcBlockchain: WalletConnectUtils.Blockchain,
        with address: String,
        walletModelProvider: WalletConnectWalletModelProvider
    ) -> BlockchainNetwork? {
        guard
            WCSupportedNamespaces(rawValue: wcBlockchain.namespace) != nil,
            let blockchain = WCUtils.makeBlockchainMeta(from: wcBlockchain),
            let walletModel = try? walletModelProvider.getModel(with: address, blockchainId: blockchain.id)
        else {
            return nil
        }

        return walletModel.tokenItem.blockchainNetwork
    }

    private func mapBlockchainNetworks(from namespaces: [String: SessionNamespace], walletModelProvider: WalletConnectWalletModelProvider) -> [BlockchainNetwork] {
        return namespaces.values.flatMap {
            let wcBlockchains = $0.accounts.compactMap { ($0.blockchain, $0.address) }

            let tangemBlockchains = wcBlockchains.compactMap {
                createBlockchainNetwork(from: $0.0, with: $0.1, walletModelProvider: walletModelProvider)
            }
            return tangemBlockchains
        }
    }
}
