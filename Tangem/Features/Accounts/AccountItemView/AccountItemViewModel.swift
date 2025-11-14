//
//  AccountItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemAccounts

final class AccountItemViewModel: ObservableObject {
    // [REDACTED_TODO_COMMENT]
    let name: String

    // [REDACTED_TODO_COMMENT]
    let iconData: AccountIconView.ViewData

    @Published var balanceFiatState: LoadableTokenBalanceView.State
    @Published var priceChangeState: TokenPriceChangeView.State

    init(
        accountModel: any CryptoAccountModel
    ) {
        name = accountModel.name
        iconData = AccountIconViewBuilder.makeAccountIconViewData(accountModel: accountModel)

        // [REDACTED_TODO_COMMENT]
        balanceFiatState = .loaded(text: .string("1,23 $"))
        priceChangeState = .loaded(signType: .positive, text: "1,14 %")
    }

    var tokensCount: String {
        "24 tokens"
    }
}
