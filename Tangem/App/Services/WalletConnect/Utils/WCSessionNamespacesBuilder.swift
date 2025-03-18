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

    var supportedChains = Set<WalletConnectUtils.Blockchain>()

    func makeAccounts(
        from wcBlockchain: WalletConnectUtils.Blockchain,
        and proposal: Session.Proposal,
        selectedWalletModelProvider: WalletConnectWalletModelProvider
    ) -> [Account]? {
        guard
            let blockchain = WCUtils.makeBlockchain(from: wcBlockchain)
        else {
            if proposal.namespaceRequiredChains.contains(wcBlockchain) {
                unsupportedEVMBlockchains.append(wcBlockchain.reference)
            }
            return nil
        }

        supportedChains.insert(wcBlockchain)

        guard
            let filteredWallets = filterWalletModels(
                by: blockchain,
                proposal: proposal,
                wcBlockchain: wcBlockchain,
                selectedWalletModelProvider: selectedWalletModelProvider
            )
        else {
            return nil
        }

        return filteredWallets.compactMap { walletModel in
            Account("\(wcBlockchain.absoluteString):\(walletModel.defaultAddressString)")
        }
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
            } else {
                missingOptionalBlockchains.append(blockchainMeta.displayName)
            }
        }

        return nil
    }
}
