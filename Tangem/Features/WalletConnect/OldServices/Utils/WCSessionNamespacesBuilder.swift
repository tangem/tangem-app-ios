//
//  WCSessionNamespacesBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit

final class WCSessionNamespacesBuilder {
    private var missingBlockchains: [String] = []

    private(set) var unsupportedEVMBlockchains: [String] = []
    private(set) var selectedChains = Set<WalletConnectUtils.Blockchain>()

    func makeConnectionRequestData(
        from wcBlockchain: WalletConnectUtils.Blockchain,
        and proposal: Session.Proposal,
        selectedOptionalBlockchains: [BlockchainNetwork],
        selectedWalletModelProvider: WalletConnectWalletModelProvider
    ) -> WCConnectionRequestDataItem? {
        guard let blockchain = WCUtils.makeBlockchainMeta(from: wcBlockchain) else {
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
            return WCConnectionRequestDataItem(
                accounts: nil,
                blockchainData: WCRequestBlockchainItemDTO(
                    wcBlockchain: wcBlockchain,
                    state: isOptionalBlockchain ? .notAdded : .requiredToAdd
                )
            )
        }

        let accounts = filteredWalletModels.compactMap { walletModel in
            Account("\(wcBlockchain.absoluteString):\(walletModel.defaultAddressString)")
        }

        let isSelectedBlockchain = selectedOptionalBlockchains.contains { $0.blockchain.networkId == blockchain.id }

        if isOptionalBlockchain, !isSelectedBlockchain {
            return WCConnectionRequestDataItem(
                accounts: accounts,
                blockchainData: WCRequestBlockchainItemDTO(
                    wcBlockchain: wcBlockchain,
                    state: .notSelected
                )
            )
        }

        selectedChains.insert(wcBlockchain)

        return WCConnectionRequestDataItem(
            accounts: accounts,
            blockchainData: WCRequestBlockchainItemDTO(
                wcBlockchain: wcBlockchain,
                state: isOptionalBlockchain ? .selected : .required
            )
        )
    }

    private func filterWalletModels(
        by blockchainMeta: WCUtils.BlockchainMeta,
        proposal: Session.Proposal,
        wcBlockchain: WalletConnectUtils.Blockchain,
        selectedWalletModelProvider: WalletConnectWalletModelProvider
    ) -> [any WalletModel]? {
        let filteredWallets = selectedWalletModelProvider.getModels(with: blockchainMeta.id)

        guard filteredWallets.isEmpty else {
            return filteredWallets
        }

        if proposal.namespaceRequiredChains.contains(wcBlockchain) {
            missingBlockchains.append(blockchainMeta.displayName)
        }

        return nil
    }
}
