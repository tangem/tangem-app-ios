//
//  MCPConnectionRequestUserWalletSelectorRowState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class UIKit.UIImage
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

        subtitle = Subtitle(
            numberOfCards: Localization.collectiblesAccountCollectionCardsCount(userWallet.numberOfCards),
            isUserWalletLocked: userWallet.isLocked,
            balance: nil
        )
        image = .loading

        isDisabled = userWallet.isLocked
        self.isSelected = isSelected
    }
}

extension MCPConnectionRequestUserWalletSelectorRowState {
    struct Subtitle: Equatable, CustomStringConvertible {
        let numberOfCards: String
        let isUserWalletLocked: Bool
        let delimiter = String.bulletSign
        var balance: String?

        var description: String {
            guard !isUserWalletLocked else {
                return "\(numberOfCards) \(delimiter) \(Localization.commonLocked)"
            }

            guard let balance else {
                return "\(numberOfCards)"
            }

            return "\(numberOfCards) \(delimiter) \(balance)"
        }
    }

    enum ImageState: Equatable {
        case loading
        case content(UIImage)
    }
}

extension MCPConnectionRequestUserWalletSelectorRowState: Identifiable {
    var id: MCPUserWallet.ID { userWallet.id }
}
