//
//  WCNetworksSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class WCNetworksSelectorViewModel: ObservableObject {
    @Published private(set) var selectedBlockchains: Set<WCSelectedBlockchainItem> = []

    let blockchains: [WCSelectedBlockchainItem]
    let requiredBlockchainNames: [String]

    var isDoneButtonDisabled: Bool {
        blockchains.contains { $0.state == .requiredToAdd2 }
    }

    var isAllRequiredChainsAdded: Bool {
        !blockchains.contains { $0.state == .requiredToAdd2 }
    }

    private let onSelectCompete: ([BlockchainNetwork]) -> Void
    private let backAction: () -> Void

    init(input: WCNetworkSelectorInput) {
        blockchains = input.blockchains
        onSelectCompete = input.onSelectCompete
        backAction = input.backAction
        requiredBlockchainNames = input.requiredBlockchainNames

        selectedBlockchains.formUnion(blockchains.filter { $0.state == .selected2 })
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .returnToConnectionDetails:
            backAction()
        case .selectNetworks:
            onSelectCompete(selectedBlockchains.map { .init($0.dataSourceBlockchain, derivationPath: nil) })
        case .blockchainSelectionChanged(let blockchain, let isSelected):
            if isSelected {
                selectedBlockchains.insert(blockchain)
            } else {
                selectedBlockchains.remove(blockchain)
            }
        }
    }

    func checkBlockchainItemDisabled(_ blockchain: WCSelectedBlockchainItem) -> Bool {
        switch blockchain.state {
        case .notAdded2, .requiredToAdd2:
            true
        case .selected2, .notSelected2, .required2:
            false
        }
    }

    func filterBlockchain(by states: [WCSelectBlockchainItemState]) -> [WCSelectedBlockchainItem] {
        blockchains.filter { states.contains($0.state) }
    }
}

// MARK: - View actions

extension WCNetworksSelectorViewModel {
    enum ViewAction {
        case selectNetworks
        case returnToConnectionDetails
        case blockchainSelectionChanged(WCSelectedBlockchainItem, Bool)
    }
}
