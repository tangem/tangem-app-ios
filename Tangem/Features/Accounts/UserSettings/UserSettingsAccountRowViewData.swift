//
//  UserSettingsAccountRowViewData.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization
import SwiftUI
import TangemAccounts

struct UserSettingsAccountRowViewData: Identifiable {
    private let accountModel: CommonCryptoAccountModel

    let onTap: () -> Void

    init?(accountModel: CommonCryptoAccountModel?, onTap: @escaping () -> Void) {
        guard let accountModel else { return nil }
        self.accountModel = accountModel
        self.onTap = onTap
    }

    init(accountModel: CommonCryptoAccountModel, onTap: @escaping () -> Void) {
        self.accountModel = accountModel
        self.onTap = onTap
    }

    var id: CommonCryptoAccountModel.AccountId {
        accountModel.id
    }

    var icon: AccountIconView.NameMode {
        switch accountModel.icon.nameMode {
        case .letter(let letter): .letter(letter)
        case .named(let name): .imageType(getNamedIcon(from: name))
        }
    }

    var iconColor: Color {
        switch accountModel.icon.color {
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

    var name: String {
        accountModel.name
    }

    // [REDACTED_TODO_COMMENT]
    var description: String {
        Localization.commonTokensCount(accountModel.walletModelsManager.walletModels.count)
    }

    private func getNamedIcon(from name: AccountModel.Icon.Name) -> ImageType {
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
}
