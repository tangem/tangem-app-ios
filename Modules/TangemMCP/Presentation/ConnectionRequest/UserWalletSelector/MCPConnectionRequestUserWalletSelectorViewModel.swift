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

    init(
        userWallets: [MCPUserWallet],
        selectedUserWalletID: MCPUserWallet.ID,
        userWalletImageRepository: MCPUserWalletImageRepository,
        balanceUpdater: @escaping (MCPUserWallet.ID) -> AsyncStream<String>,
        selectionChanged: @escaping (MCPUserWallet) -> Void
    ) {
        self.selectionChanged = selectionChanged

        weak var futureSelf: MCPConnectionRequestUserWalletSelectorViewModel?

        state = MCPConnectionRequestUserWalletSelectorState(
            userWallets: userWallets.map { userWallet in
                MCPConnectionRequestUserWalletSelectorRowViewModel(
                    state: MCPConnectionRequestUserWalletSelectorRowState(
                        userWallet,
                        isSelected: userWallet.id == selectedUserWalletID
                    ),
                    imageRepository: userWalletImageRepository,
                    balanceUpdater: balanceUpdater,
                    tapAction: { selectedUserWalletState in
                        futureSelf?.handle(action: .selectionChanged(selectedUserWalletState))
                    }
                )
            },
        )

        futureSelf = self
    }

    func handle(action: MCPConnectionRequestUserWalletSelectorAction) {
        switch action {
        case .selectionChanged(let selectedUserWalletState):
            selectionChanged(selectedUserWalletState.userWallet)

            for userWalletRowViewModel in state.userWallets {
                let isSelected = userWalletRowViewModel.state.id == selectedUserWalletState.id
                userWalletRowViewModel.handle(action: .isSelectedChanged(isSelected))
            }
        }
    }
}
