//
//  AccountModelMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum AccountModelMapper {
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
}
