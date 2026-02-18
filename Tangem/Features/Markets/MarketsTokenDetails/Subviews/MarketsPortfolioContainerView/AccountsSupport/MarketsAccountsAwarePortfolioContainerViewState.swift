//
//  MarketsAccountsAwarePortfolioContainerViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import Foundation
import TangemMacro
import TangemFoundation

extension MarketsAccountsAwarePortfolioContainerViewModel {
    @CaseFlagable
    enum TypeView {
        case empty
        case list(ListStyle)
        case unsupported
        case unavailable
        case loading
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
