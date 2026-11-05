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
    private let selectionRequested: (MCPUserWallet) -> Void

    @Published private(set) var state: MCPConnectionRequestUserWalletSelectorState

    init(
        userWallets: [MCPUserWallet],
        selectedUserWalletID: MCPUserWallet.ID,
        userWalletImageRepository: MCPUserWalletImageRepository,
        balanceUpdater: @escaping (MCPUserWallet.ID) -> AsyncStream<String>,
        selectionRequested: @escaping (MCPUserWallet) -> Void
    ) {
        self.selectionRequested = selectionRequested

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
                    tapAction: { userWalletState in
                        futureSelf?.handle(action: .rowTapped(userWalletState))
                    }
                )
            }
        )

        futureSelf = self
    }

    func handle(action: MCPConnectionRequestUserWalletSelectorAction) {
        switch action {
        case .rowTapped(let userWalletState):
            selectionRequested(userWalletState.userWallet)

        case .selectionUpdated(let selectedUserWalletID):
            for userWalletRowViewModel in state.userWallets {
                let isSelected = userWalletRowViewModel.state.id == selectedUserWalletID
                userWalletRowViewModel.handle(action: .isSelectedChanged(isSelected))
            }
        }
    }
}
