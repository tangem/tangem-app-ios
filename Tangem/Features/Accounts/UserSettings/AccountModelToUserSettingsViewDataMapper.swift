//
//  AccountModelMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import TangemLocalization

enum AccountModelToUserSettingsViewDataMapper {
    static func map(
        from accountModel: AccountModel,
        onTap: @escaping (any BaseAccountModel) -> Void
    ) -> [UserSettingsAccountsViewModel._UserSettingsAccountRowViewData] {
        switch accountModel {
        case .standard(let cryptoAccounts):
            mapStandardCryptoAccounts(cryptoAccounts, onTap: onTap)
        }
    }

    private static func mapStandardCryptoAccounts(
        _ cryptoAccounts: CryptoAccounts,
        onTap: @escaping (any CryptoAccountModel) -> Void
    ) -> [UserSettingsAccountsViewModel._UserSettingsAccountRowViewData] {
        switch cryptoAccounts {
        case .single:
            // No accounts are displayed until .single case is in action
            return []

        case .multiple(let cryptoAccountModel):
            return cryptoAccountModel.map { accountModel in
                mapCryptoAccount(
                    accountModel,
                    onTap: { model in
                        onTap(model)
                    }
                )
            }
        }
    }

    private static func mapCryptoAccount(
        _ cryptoAccountModel: any CryptoAccountModel,
        onTap: @escaping (any CryptoAccountModel) -> Void
    ) -> UserSettingsAccountsViewModel._UserSettingsAccountRowViewData {
        let accountIconViewData = AccountIconViewBuilder.makeAccountIconViewData(accountModel: cryptoAccountModel)
        let viewData = UserSettingsAccountRowViewData(
            id: cryptoAccountModel.id,
            name: cryptoAccountModel.name,
            accountIconViewData: accountIconViewData,
            description: Localization.commonTokensCount(cryptoAccountModel.userTokensManager.userTokens.count),
            balancePublisher: cryptoAccountModel.fiatTotalBalanceProvider.totalFiatBalancePublisher,
            onTap: {
                onTap(cryptoAccountModel)
            }
        )

        return UserSettingsAccountsViewModel._UserSettingsAccountRowViewData(
            viewData: viewData,
            persId: cryptoAccountModel.id
        )
    }
}
