//
//  AccountModelUtils.UI.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemAccounts

// [REDACTED_TODO_COMMENT]
extension AccountModelUtils {
    enum UI {
        static func iconColor(from color: AccountModel.CompositeIcon.Color) -> Color {
            CompositeIconColorPalette.color(for: color)
        }

        static func iconAsset(from name: AccountModel.CompositeIcon.Name) -> ImageType {
            switch name {
            case .airplaneMode:
                return Assets.Accounts.airplane
            case .beach:
                return Assets.Accounts.beach
            case .bookmark:
                return Assets.Accounts.bookmark
            case .clock:
                return Assets.Accounts.clock
            case .family:
                return Assets.Accounts.family
            case .favorite:
                return Assets.Accounts.favorite
            case .gift:
                return Assets.Accounts.gift
            case .home:
                return Assets.Accounts.home
            case .letter:
                return Assets.Accounts.letter
            case .money:
                return Assets.Accounts.money
            case .package:
                return Assets.Accounts.package
            case .safe:
                return Assets.Accounts.safe
            case .shirt:
                return Assets.Accounts.shirt
            case .shoppingBasket:
                return Assets.Accounts.shoppingBasket
            case .star:
                return Assets.Accounts.starAccounts
            case .startUp:
                return Assets.Accounts.startUp
            case .user:
                return Assets.Accounts.user
            case .wallet:
                return Assets.Accounts.walletAccounts
            }
        }

        static func standaloneIconAsset(from standaloneIcon: AccountModel.StandaloneIcon) -> ImageType {
            switch standaloneIcon {
            case .tangemPay:
                return Assets.Visa.accountAvatar
            }
        }

        static func newAccountIcon() -> AccountModel.CompositeIcon {
            let iconColor = CompositeIconColor.randomElement()

            var allIconNames = AccountModel.CompositeIcon.Name.allCases.toSet()
            allIconNames.remove(.letter)
            allIconNames.remove(.star)
            let iconName = allIconNames.randomElement() ?? .wallet

            return AccountModel.CompositeIcon(name: iconName, color: iconColor)
        }
    }
}

// MARK: - Convenience extensions

extension AccountModelUtils.UI {
    static func iconViewData(
        icon: AccountModel.Icon,
        accountName: String
    ) -> AccountIconView.ViewData {
        switch icon {
        case .composite(let compositeIcon):
            iconViewData(compositeIcon: compositeIcon, accountName: accountName)
        case .standalone(let standaloneIcon):
            .standalone(image: standaloneIconAsset(from: standaloneIcon))
        }
    }

    static func iconViewData(
        compositeIcon: AccountModel.CompositeIcon,
        accountName: String
    ) -> AccountIconView.ViewData {
        .composite(
            backgroundColor: iconColor(from: compositeIcon.color),
            nameMode: nameMode(from: compositeIcon.name, accountName: accountName)
        )
    }

    static func iconViewData(accountModel: any BaseAccountModel) -> AccountIconView.ViewData {
        iconViewData(icon: accountModel.icon.erased, accountName: accountModel.name)
    }
}

// MARK: - Private implementation

private extension AccountModelUtils.UI {
    static func nameMode(from name: AccountModel.CompositeIcon.Name, accountName: String) -> AccountIconView.NameMode {
        switch name {
        case .letter:
            .letter(accountName.first.map { String($0) } ?? "")
        default:
            .imageType(iconAsset(from: name))
        }
    }
}
