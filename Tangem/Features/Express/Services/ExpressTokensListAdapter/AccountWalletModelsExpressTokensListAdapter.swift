//
//  AccountWalletModelsExpressTokensListAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct AccountWalletModelsExpressTokensListAdapter: ExpressTokensListAdapter {
    private let accountModelsManager: AccountModelsManager

    init(accountModelsManager: AccountModelsManager) {
        self.accountModelsManager = accountModelsManager
    }

    func walletModels() -> AnyPublisher<[any WalletModel], Never> {
        AccountWalletModelsAggregator.walletModelsPublisher(from: accountModelsManager)
    }
}
