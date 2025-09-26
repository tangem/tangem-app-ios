//
//  AccountModelMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts

enum AccountModelToUserSettingsViewDataMapper {
    static func map(from accountModel: AccountModel, onTap: @escaping (any BaseAccountModel) -> Void) -> [UserSettingsAccountRowViewData] {
        switch accountModel {
        case .standard(let cryptoAccounts):
            mapStandardCryptoAccounts(cryptoAccounts, onTap: onTap)
        }
    }

    private static func mapStandardCryptoAccounts(
        _ accounts: CryptoAccounts,
        onTap: @escaping (any BaseAccountModel) -> Void
    ) -> [UserSettingsAccountRowViewData] {
        switch accounts {
        case .single(let account):
            return [
                mapAccount(
                    account,
                    onTap: { model in
                        onTap(model)
                    }
                ),
            ]

        case .multiple(let cryptoAccountModel):
            return cryptoAccountModel.map { accountModel in
                mapAccount(
                    accountModel,
                    onTap: { model in
                        onTap(model)
                    }
                )
            }
        }
    }

    private static func mapAccount(
        _ accountModel: any BaseAccountModel,
        onTap: @escaping (any BaseAccountModel) -> Void
    ) -> UserSettingsAccountRowViewData {
        let iconNameMode: AccountIconView.NameMode = switch accountModel.icon.name {
        case .letter:
            .letter(String(accountModel.name.first ?? "_"))

        default:
            .imageType(AccountModelUtils.UI.iconAsset(from: accountModel.icon.name))
        }

        return UserSettingsAccountRowViewData(
            id: "\(accountModel.id)",
            name: accountModel.name,
            iconNameMode: iconNameMode,
            // [REDACTED_TODO_COMMENT]
            description: "",
            iconColor: AccountModelUtils.UI.iconColor(from: accountModel.icon.color),
            onTap: {
                onTap(accountModel)
            }
        )
    }
}
