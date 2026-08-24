//
//  TransactionDetailsContext.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts
import TangemUI

struct TransactionDetailsContext {
    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo
    private let isAccountsMode: Bool

    let tokenIconInfo: TokenIconInfo

    init(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        isAccountsMode: Bool
    ) {
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
        self.isAccountsMode = isAccountsMode
        tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }

    var tokenSymbol: String {
        walletModel.tokenItem.currencySymbol
    }

    var tokenCurrencyId: String? {
        walletModel.tokenItem.currencyId
    }

    var receiverName: String {
        guard isAccountsMode, let account = walletModel.account else {
            return userWalletInfo.name
        }

        return account.name
    }

    var receiverAccountIcon: AccountIconView.ViewData? {
        guard isAccountsMode, let account = walletModel.account else {
            return nil
        }

        return AccountModelUtils.UI.iconViewData(accountModel: account)
    }

    func exploreTransactionURL(for hash: String) -> URL? {
        walletModel.exploreTransactionURL(for: hash)
    }
}
