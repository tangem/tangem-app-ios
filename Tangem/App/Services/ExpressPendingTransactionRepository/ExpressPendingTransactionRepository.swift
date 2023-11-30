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
    var pendingTransactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> { get }

    func initializeForUserWallet(with userWalletId: UserWalletId)
    func hasPendingTransaction(in networkId: String) -> Bool
    func lastCurrencyTransaction() -> ExpressCurrency?

    func didSendApproveTransaction()
    func didSendSwapTransaction(_ txData: SentExpressTransactionData)
    func removeSwapTransaction(with expressTxId: String)
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
