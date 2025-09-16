//
//  AccountModelMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccounts

enum AccountModelMapper {
    // MARK: - Account

    static func map(from accountModel: AccountModel, onTap: @escaping (CommonCryptoAccountModel) -> Void) -> [UserSettingsAccountRowViewData] {
        switch accountModel {
        case .standard(let cryptoAccounts):
            mapStandardCryptoAccounts(cryptoAccounts, onTap: onTap)
        }
    }

    private static func mapStandardCryptoAccounts(
        _ accounts: CryptoAccounts,
        onTap: @escaping (CommonCryptoAccountModel) -> Void
    ) -> [UserSettingsAccountRowViewData] {
        switch accounts {
        case .single:
            return []
        case .multiple(let cryptoAccountModel):
            return cryptoAccountModel.compactMap {
                guard let commonCryptoAccount = $0 as? CommonCryptoAccountModel else {
                    return nil
                }
                return UserSettingsAccountRowViewData(
                    accountModel: commonCryptoAccount,
                    onTap: {
                        onTap(commonCryptoAccount)
                    }
                )
            }
        }
    }

    // MARK: - Color

    static func mapAccountColor(_ accountColor: AccountModel.Icon.Color) -> Color {
        switch accountColor {
        case .brightBlue: Colors.Accounts.brightBlue
        case .coralRed: Colors.Accounts.coralRed
        case .cyan: Colors.Accounts.cyan
        case .darkGreen: Colors.Accounts.darkGreen
        case .deepPurple: Colors.Accounts.deepPurple
        case .hotPink: Colors.Accounts.hotPink
        case .lavender: Colors.Accounts.lavender
        case .magenta: Colors.Accounts.magenta
        case .mediumGreen: Colors.Accounts.mediumGreen
        case .purple: Colors.Accounts.purple
        case .royalBlue: Colors.Accounts.royalBlue
        case .yellow: Colors.Accounts.yellow
        }
    }

    private static func mapColor(_ color: Color) -> AccountModel.Icon.Color? {
        switch color {
        case Colors.Accounts.brightBlue: .brightBlue
        case Colors.Accounts.coralRed: .coralRed
        case Colors.Accounts.cyan: .cyan
        case Colors.Accounts.darkGreen: .darkGreen
        case Colors.Accounts.deepPurple: .deepPurple
        case Colors.Accounts.hotPink: .hotPink
        case Colors.Accounts.lavender: .lavender
        case Colors.Accounts.magenta: .magenta
        case Colors.Accounts.mediumGreen: .mediumGreen
        case Colors.Accounts.purple: .purple
        case Colors.Accounts.royalBlue: .royalBlue
        case Colors.Accounts.yellow: .yellow
        default: nil
        }
    }

    // MARK: - Image

    static func mapToAccountModelIcon(_ gridItemImage: GridItemImage, color: GridItemColor, accountName: String) -> AccountModel.Icon? {
        guard
            let color = mapColor(color.color),
            let iconNameMode = mapImageGridItemType(gridItemImage.kind, accountName: accountName)
        else {
            return nil
        }

        return AccountModel.Icon(nameMode: iconNameMode, color: color)
    }

    static func mapAccountImageName(_ name: AccountModel.Icon.Name) -> ImageType {
        switch name {
        case .airplane: Assets.Accounts.airplane
        case .beach: Assets.Accounts.beach
        case .bookmark: Assets.Accounts.bookmark
        case .clock: Assets.Accounts.clock
        case .family: Assets.Accounts.family
        case .favorite: Assets.Accounts.favorite
        case .gift: Assets.Accounts.gift
        case .home: Assets.Accounts.home
        case .letter: Assets.Accounts.letter
        case .money: Assets.Accounts.money
        case .package: Assets.Accounts.package
        case .safe: Assets.Accounts.safe
        case .shirt: Assets.Accounts.shirt
        case .shoppingBasket: Assets.Accounts.shoppingBasket
        case .star: Assets.Accounts.starAccounts
        case .startUp: Assets.Accounts.startUp
        case .user: Assets.Accounts.user
        case .wallet: Assets.Accounts.walletAccounts
        }
    }

    private static func mapImageGridItemType(_ gridItemImageKind: GridItemImageKind, accountName: String) -> AccountModel.Icon.NameMode? {
        switch gridItemImageKind {
        case .image(let imageType):
            return if let name = mapImageType(imageType) {
                .named(name)
            } else {
                nil
            }

        case .letter:
            return if let firstLetter = accountName.first {
                .letter(String(firstLetter))
            } else {
                nil
            }
        }
    }

    private static func mapImageType(_ imageType: ImageType) -> AccountModel.Icon.Name? {
        switch imageType {
        case Assets.Accounts.airplane: .airplane
        case Assets.Accounts.beach: .beach
        case Assets.Accounts.bookmark: .bookmark
        case Assets.Accounts.clock: .clock
        case Assets.Accounts.family: .family
        case Assets.Accounts.favorite: .favorite
        case Assets.Accounts.gift: .gift
        case Assets.Accounts.home: .home
        case Assets.Accounts.letter: .letter
        case Assets.Accounts.money: .money
        case Assets.Accounts.package: .package
        case Assets.Accounts.safe: .safe
        case Assets.Accounts.shirt: .shirt
        case Assets.Accounts.shoppingBasket: .shoppingBasket
        case Assets.Accounts.starAccounts: .star
        case Assets.Accounts.startUp: .startUp
        case Assets.Accounts.user: .user
        case Assets.Accounts.walletAccounts: .wallet
        default: nil
        }
    }
}
