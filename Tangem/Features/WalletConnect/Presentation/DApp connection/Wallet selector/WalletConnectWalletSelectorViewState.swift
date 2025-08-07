//
//  WalletConnectWalletSelectorViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct SwiftUI.Image
import TangemLocalization
import TangemFoundation

// [REDACTED_TODO_COMMENT]
struct WalletConnectWalletSelectorViewState {
    let navigationTitle = "Choose wallet"
    var wallets: [UserWallet]
}

extension WalletConnectWalletSelectorViewState {
    struct UserWallet: Identifiable {
        let domainModel: any UserWalletModel

        let id: UserWalletId
        let name: String
        let isLocked: Bool
        var imageState: ImageState
        var description: Description
        var isSelected: Bool

        init(domainModel: some UserWalletModel, imageState: ImageState, description: Description, isSelected: Bool) {
            self.domainModel = domainModel
            id = domainModel.userWalletId
            name = domainModel.name
            isLocked = domainModel.isUserWalletLocked
            self.imageState = imageState
            self.description = description
            self.isSelected = isSelected
        }
    }
}

extension WalletConnectWalletSelectorViewState.UserWallet {
    enum ImageState {
        case loading
        case content(SwiftUI.Image)
    }

    struct Description {
        let tokensCount: String
        let delimiter = AppConstants.dotSign
        var balanceState: LoadableTokenBalanceView.State
    }
}
