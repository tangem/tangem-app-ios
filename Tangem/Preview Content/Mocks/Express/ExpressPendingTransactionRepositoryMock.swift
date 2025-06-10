//
//  ExpressPendingTransactionRepositoryMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ExpressPendingTransactionRepositoryMock: ExpressPendingTransactionRepository {
    var transactions: [ExpressPendingTransactionRecord] { [] }

    var transactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> { .just(output: []) }

    func updateItems(_ items: [ExpressPendingTransactionRecord]) {}

    func swapTransactionDidSend(_ txData: SentExpressTransactionData, userWalletId: String) {}

    func onrampTransactionDidSend(_ txData: SentOnrampTransactionData, userWalletId: String) {}

    func hideSwapTransaction(with id: String) {}
}
