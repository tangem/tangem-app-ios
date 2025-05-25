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
}

extension WalletConnectWalletSelectorViewState {
    struct UserWallet: Identifiable {
        let domainModel: any UserWalletModel

        let id: UserWalletId
        let name: String
        let isLocked: Bool
        var imageState: ContentState<SwiftUI.Image>
        var descriptionState: ContentState<String>
        var isSelected: Bool

        init(domainModel: some UserWalletModel, imageState: ContentState<SwiftUI.Image>, descriptionState: ContentState<String>, isSelected: Bool) {
            self.domainModel = domainModel
            id = domainModel.userWalletId
            name = domainModel.name
            isLocked = domainModel.isUserWalletLocked
            self.imageState = imageState
            self.descriptionState = descriptionState
            self.isSelected = isSelected
        }
    }
}

extension WalletConnectWalletSelectorViewState.UserWallet {
    enum ContentState<Content> {
        case loading
        case content(Content)
    }
}
