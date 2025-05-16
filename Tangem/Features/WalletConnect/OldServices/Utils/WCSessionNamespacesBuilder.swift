//
//  WCSessionNamespacesBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit

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
    ) -> WCConnectionRequestDataItem? {
        guard
            let blockchain = WCUtils.makeBlockchainMeta(from: wcBlockchain)
        else {
            if proposal.namespaceRequiredChains.contains(wcBlockchain) {
                unsupportedEVMBlockchains.append(wcBlockchain.reference)
            }

            return nil
        }
        let isOptionalBlockchain = !proposal.namespaceRequiredChains.contains(wcBlockchain)

        guard
            let filteredWalletModels = filterWalletModels(
                by: blockchain,
                proposal: proposal,
                wcBlockchain: wcBlockchain,
                selectedWalletModelProvider: selectedWalletModelProvider
            )
        else {
            return makeBlockchainData(from: wcBlockchain, with: isOptionalBlockchain ? .notAdded : .requiredToAdd)
        }

        let isSelectedBlockchain = selectedOptionalBlockchains.contains { $0.blockchain.networkId == blockchain.id }

        if isOptionalBlockchain, !isSelectedBlockchain {
            return makeBlockchainData(from: wcBlockchain, with: .notSelected)
        }

        let accounts = filteredWalletModels.compactMap { walletModel in
            Account("\(wcBlockchain.absoluteString):\(walletModel.defaultAddressString)")
        }

        supportedChains.insert(wcBlockchain)

        return makeBlockchainData(
            from: wcBlockchain,
            with: isOptionalBlockchain ? .selected : .required,
            accounts: accounts
        )
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

    private func makeBlockchainData(
        from wcBlockchain: WalletConnectUtils.Blockchain,
        with state: WCSelectBlockchainItemState,
        accounts: [Account]? = nil
    ) -> WCConnectionRequestDataItem {
        .init(accounts: accounts, blockchainData: .init(wcBlockchain: wcBlockchain, state: state))
    }
}
