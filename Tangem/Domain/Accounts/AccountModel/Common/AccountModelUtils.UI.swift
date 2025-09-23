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

extension AccountModelUtils {
    enum UI {
        static func iconColor(from color: AccountModel.Icon.Color) -> Color {
            switch color {
            case .azure:
                return Colors.Accounts.azureBlue
            case .caribbeanBlue:
                return Colors.Accounts.caribbeanBlue
            case .dullLavender:
                return Colors.Accounts.dullLavender
            case .candyGrapeFizz:
                return Colors.Accounts.candyGrapeFizz
            case .sweetDesire:
                return Colors.Accounts.sweetDesire
            case .palatinateBlue:
                return Colors.Accounts.palatinateBlue
            case .fuchsiaNebula:
                return Colors.Accounts.fuchsiaNebula
            case .mexicanPink:
                return Colors.Accounts.mexicanPink
            case .pelati:
                return Colors.Accounts.pelati
            case .pattypan:
                return Colors.Accounts.pattypan
            case .ufoGreen:
                return Colors.Accounts.ufoGreen
            case .vitalGreen:
                return Colors.Accounts.vitalGreen
            }
        }

        static func iconAsset(from name: AccountModel.Icon.Name) -> ImageType {
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

        static func accountIconColor(from color: Color) -> AccountModel.Icon.Color? {
            switch color {
            case Colors.Accounts.azureBlue:
                return .azure
            case Colors.Accounts.caribbeanBlue:
                return .caribbeanBlue
            case Colors.Accounts.dullLavender:
                return .dullLavender
            case Colors.Accounts.candyGrapeFizz:
                return .candyGrapeFizz
            case Colors.Accounts.sweetDesire:
                return .sweetDesire
            case Colors.Accounts.palatinateBlue:
                return .palatinateBlue
            case Colors.Accounts.fuchsiaNebula:
                return .fuchsiaNebula
            case Colors.Accounts.mexicanPink:
                return .mexicanPink
            case Colors.Accounts.pelati:
                return .pelati
            case Colors.Accounts.pattypan:
                return .pattypan
            case Colors.Accounts.ufoGreen:
                return .ufoGreen
            case Colors.Accounts.vitalGreen:
                return .vitalGreen
            default:
                return nil
            }
        }
    }
}

// MARK: - Convenience extensions

extension AccountModelUtils.UI {
    static func iconColor(from icon: AccountModel.Icon) -> Color {
        return iconColor(from: icon.color)
    }

    static func iconImage(from name: AccountModel.Icon.Name) -> Image {
        return iconAsset(from: name).image
    }
}
