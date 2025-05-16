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
        blockchains.contains { $0.state == .requiredToAdd }
    }
    
    var isAllRequiredChainsAdded: Bool {
        !blockchains.contains { $0.state == .requiredToAdd }
    }

    private let onSelectCompete: ([BlockchainNetwork]) -> Void
    private let backAction: () -> Void

    init(input: WCNetworkSelectorInput) {
        blockchains = input.blockchains
        onSelectCompete = input.onSelectCompete
        backAction = input.backAction
        requiredBlockchainNames = input.requiredBlockchainNames

        selectedBlockchains.formUnion(blockchains.filter { $0.state == .selected })
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
        case .notAdded, .requiredToAdd:
            true
        case .selected, .notSelected, .required:
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
