//
//  ExpressPendingTransactionRepository.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping

protocol ExpressPendingTransactionRepository: AnyObject {
    var allExpressTransactions: [ExpressPendingTransactionRecord] { get }
    var pendingCEXTransactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> { get }

    func updateItems(_ items: [ExpressPendingTransactionRecord])
    func swapTransactionDidSend(_ txData: SentExpressTransactionData, userWalletId: String)
}

private struct ExpressPendingTransactionRepositoryKey: InjectionKey {
    static var currentValue: ExpressPendingTransactionRepository = CommonExpressPendingTransactionRepository()
}

extension InjectedValues {
    var expressPendingTransactionsRepository: ExpressPendingTransactionRepository {
        get { Self[ExpressPendingTransactionRepositoryKey.self] }
        set { Self[ExpressPendingTransactionRepositoryKey.self] = newValue }
    }
}
