//
//  WCSessionNamespacesBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit

struct WCConnectionRequestData {
    let accounts: [Account]?
    let selectedBlockchain: Blockchain?
    let availableToSelectBlockchain: Blockchain?
    let notAddedBlockchain: Blockchain?

    init(
        accounts: [Account]? = nil,
        selectedBlockchain: Blockchain? = nil,
        availableToSelectBlockchain: Blockchain? = nil,
        notAddedBlockchain: Blockchain? = nil
    ) {
        self.accounts = accounts
        self.selectedBlockchain = selectedBlockchain
        self.availableToSelectBlockchain = availableToSelectBlockchain
        self.notAddedBlockchain = notAddedBlockchain
    }
}

final class WCSessionNamespacesBuilder {
    private(set) var missingBlockchains: [String] = []
    private(set) var missingOptionalBlockchains: [String] = []
    private(set) var unsupportedEVMBlockchains: [String] = []
    private(set) var supportedChains = Set<WalletConnectUtils.Blockchain>()

    func makeConnectionRequestData(
        from wcBlockchain: WalletConnectUtils.Blockchain,
        and proposal: Session.Proposal,
        selectedOptionalBlockchains: [BlockchainNetwork],
        selectedWalletModelProvider: WalletConnectWalletModelProvider
    ) -> WCConnectionRequestData? {
        guard
            let blockchain = WCUtils.makeBlockchainMeta(from: wcBlockchain)
        else {
            if proposal.namespaceRequiredChains.contains(wcBlockchain) {
                unsupportedEVMBlockchains.append(wcBlockchain.reference)
            }

            return nil
        }

        supportedChains.insert(wcBlockchain)

        guard
            let filteredWalletModels = filterWalletModels(
                by: blockchain,
                proposal: proposal,
                wcBlockchain: wcBlockchain,
                selectedWalletModelProvider: selectedWalletModelProvider
            )
        else {
            return .init(notAddedBlockchain: wcBlockchain)
        }

        let isOptionalBlockchain = !proposal.namespaceRequiredChains.contains(wcBlockchain)
        let isSelectedBlockchain = selectedOptionalBlockchains.contains { $0.blockchain.networkId == blockchain.id }

        if isOptionalBlockchain, !isSelectedBlockchain {
            return .init(availableToSelectBlockchain: wcBlockchain)
        }

        let accounts = filteredWalletModels.compactMap { walletModel in
            Account("\(wcBlockchain.absoluteString):\(walletModel.defaultAddressString)")
        }

        return .init(accounts: accounts, selectedBlockchain: wcBlockchain)
    }

    private func filterWalletModels(
        by blockchainMeta: WCUtils.BlockchainMeta,
        proposal: Session.Proposal,
        wcBlockchain: WalletConnectUtils.Blockchain,
        selectedWalletModelProvider: WalletConnectWalletModelProvider
    ) -> [any WalletModel]? {
        let filteredWallets = selectedWalletModelProvider.getModels(with: blockchainMeta.id)

        if filteredWallets.isNotEmpty {
            return filteredWallets
        } else {
            if proposal.namespaceRequiredChains.contains(wcBlockchain) {
                missingBlockchains.append(blockchainMeta.displayName)
            }
        }

        return nil
    }
}
