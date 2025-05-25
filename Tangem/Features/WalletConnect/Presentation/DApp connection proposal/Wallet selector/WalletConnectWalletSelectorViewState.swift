//
//  WalletConnectWalletSelectorViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct SwiftUI.Image
import TangemLocalization

// [REDACTED_TODO_COMMENT]
struct WalletConnectWalletSelectorViewState {
    let navigationTitle = "Choose wallet"
    var wallets: [UserWallet]

    static func loading(userWallets: [any UserWalletModel], selectedWallet: some UserWalletModel) -> WalletConnectWalletSelectorViewState {
        return WalletConnectWalletSelectorViewState(
            wallets: userWallets.map { userWallet in
                UserWallet(domainModel: userWallet, state: .loading, isSelected: userWallet.userWalletId == selectedWallet.userWalletId)
            }
        )
    }
}

extension WalletConnectWalletSelectorViewState {
    struct UserWallet: Identifiable {
        let domainModel: any UserWalletModel

        let id: UserWalletId
        let name: String
        let isLocked: Bool
        var state: State
        var isSelected: Bool

        init(domainModel: some UserWalletModel, state: State, isSelected: Bool) {
            self.domainModel = domainModel
            id = domainModel.userWalletId
            name = domainModel.name
            isLocked = domainModel.isUserWalletLocked
            self.state = state
            self.isSelected = isSelected
        }
    }
}

extension WalletConnectWalletSelectorViewState.UserWallet {
    enum State {
        case loading
        case content(ContentState)
    }

    struct ContentState {
        let image: SwiftUI.Image
        let description: String
    }
}
