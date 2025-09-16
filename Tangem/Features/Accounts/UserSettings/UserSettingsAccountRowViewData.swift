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
        AccountModelMapper.mapAccountColor(accountModel.icon.color)
    }

    var name: String {
        accountModel.name
    }

    // [REDACTED_TODO_COMMENT]
    var description: String {
        Localization.commonTokensCount(accountModel.walletModelsManager.walletModels.count)
    }

    private func getNamedIcon(from name: AccountModel.Icon.Name) -> ImageType {
        AccountModelMapper.mapAccountImageName(name)
    }
}
