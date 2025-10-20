//
//  MarketsAccountsAwarePortfolioContainerViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import Foundation
import TangemFoundation

extension MarketsAccountsAwarePortfolioContainerViewModel {
    enum TypeView {
        case empty
        case list(ListStyle)
        case unsupported
        case unavailable
        case loading

        var isList: Bool {
            if case .list = self {
                return true
            }

            return false
        }
    }
}

extension MarketsAccountsAwarePortfolioContainerViewModel.TypeView {
    enum ListStyle {
        case justWallets([UserWalletWithTokensData])
        case walletsWithAccounts([UserWalletWithAccountsData])
    }

    struct UserWalletWithAccountsData {
        let userWalletId: UserWalletId
        let userWalletName: String
        let accountsWithTokenItems: [AccountWithTokenItemsData]
    }

    struct AccountWithTokenItemsData {
        let accountData: AccountData
        let tokenItems: [MarketsPortfolioTokenItemViewModel]
    }

    struct AccountData {
        let id: AnyHashable
        let name: String
        let iconInfo: AccountIconView.ViewData
    }

    struct UserWalletWithTokensData {
        let userWalletId: UserWalletId
        let userWalletName: String
        let tokenItems: [MarketsPortfolioTokenItemViewModel]
    }
}
