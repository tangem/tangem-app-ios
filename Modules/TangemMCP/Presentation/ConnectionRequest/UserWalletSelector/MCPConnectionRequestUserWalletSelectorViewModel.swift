//
//  MCPConnectionRequestUserWalletSelectorViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol Combine.ObservableObject
import struct Combine.Published
import struct TangemFoundation.UserWalletId

@MainActor
final class MCPConnectionRequestUserWalletSelectorViewModel: ObservableObject, HashableObject {
    private let selectionChanged: (MCPUserWallet) -> Void

    @Published private(set) var state: MCPConnectionRequestUserWalletSelectorState

    init(state: MCPConnectionRequestUserWalletSelectorState, selectionChanged: @escaping (MCPUserWallet) -> Void) {
        self.state = state
        self.selectionChanged = selectionChanged
    }

    func handle(action: MCPConnectionRequestUserWalletSelectorAction) {
        switch action {
        case .selectionChanged(let selectedUserWallet):
            state.selectedUserWalletID = selectedUserWallet.id
            selectionChanged(selectedUserWallet)
        }
    }
}
