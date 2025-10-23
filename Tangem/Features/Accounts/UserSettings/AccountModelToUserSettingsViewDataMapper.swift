//
//  AccountModelMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts

enum AccountModelToUserSettingsViewDataMapper {
    static func map(
        from accountModel: AccountModel,
        onTap: @escaping (any BaseAccountModel) -> Void
    ) -> [UserSettingsAccountRowViewData] {
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
        let accountIconViewData = AccountIconViewBuilder().makeAccountIconViewData(accountModel: accountModel)

        return UserSettingsAccountRowViewData(
            id: "\(accountModel.id)",
            name: accountModel.name,
            accountIconViewData: accountIconViewData,
            // [REDACTED_TODO_COMMENT]
            description: "",
            onTap: {
                onTap(accountModel)
            }
        )
    }
}
