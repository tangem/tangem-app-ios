//
//  MCPConnectionRequestUserWalletSelectorRowState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class UIKit.UIImage
import TangemAssets
import TangemFoundation
private import enum TangemLocalization.Localization

struct MCPConnectionRequestUserWalletSelectorRowState: Equatable {
    let userWallet: MCPUserWallet

    let title: String
    var subtitle: Subtitle
    var image: ImageState

    let isDisabled: Bool
    var isSelected: Bool

    init(_ userWallet: MCPUserWallet, isSelected: Bool) {
        self.userWallet = userWallet
        title = userWallet.name

        subtitle = userWallet.isLocked ? .locked : .loading
        image = userWallet.isMobileWallet
            ? .mobileWallet(DesignSystem.Icons.Cloud.filled32)
            : .loading

        isDisabled = userWallet.isLocked
        self.isSelected = isSelected
    }
}

extension MCPConnectionRequestUserWalletSelectorRowState {
    enum Subtitle: Equatable {
        case locked
        case loading
        case balance(String)

        var text: String? {
            switch self {
            case .locked:
                Localization.commonLocked
            case .loading:
                nil
            case .balance(let balance):
                balance
            }
        }
    }

    enum ImageState: Equatable {
        case loading
        case content(UIImage)
        case mobileWallet(ImageType)
    }
}

extension MCPConnectionRequestUserWalletSelectorRowState: Identifiable {
    var id: MCPUserWallet.ID { userWallet.id }
}
