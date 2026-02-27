//
//  AccountsAwareTokenSelectorTangemPayItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct AccountsAwareTokenSelectorTangemPayItemsProvider {
    let userWalletInfo: UserWalletInfo
    let tangemPayAccount: TangemPayAccount
}

// MARK: - AccountsAwareTokenSelectorAccountModelItemsProvider

extension AccountsAwareTokenSelectorTangemPayItemsProvider: AccountsAwareTokenSelectorAccountModelItemsProvider {
    var items: [AccountsAwareTokenSelectorItem] {
        [makeTangemPayItem()]
    }

    var itemsPublisher: AnyPublisher<[AccountsAwareTokenSelectorItem], Never> {
        Just([makeTangemPayItem()]).eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension AccountsAwareTokenSelectorTangemPayItemsProvider {
    func makeTangemPayItem() -> AccountsAwareTokenSelectorItem {
        AccountsAwareTokenSelectorItem(
            userWalletInfo: userWalletInfo,
            source: .tangemPay(tangemPayAccount)
        )
    }
}
