//
//  FakePendingExpressTransactionsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class FakePendingExpressTransactionsManager: PendingExpressTransactionsManager {
    var pendingTransactions: [PendingTransaction] { [] }
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> {
        Just(pendingTransactions).eraseToAnyPublisher()
    }

    func hideTransaction(with id: String) {}
}
