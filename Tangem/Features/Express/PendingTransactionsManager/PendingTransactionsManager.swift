//
//  PendingTransactionsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

enum PendingTransactionType {
    case swap(source: ExpressPendingTransactionRecord.TokenTxInfo, destination: ExpressPendingTransactionRecord.TokenTxInfo)
    case onramp(sourceAmount: Decimal, sourceCurrencySymbol: String, destination: ExpressPendingTransactionRecord.TokenTxInfo)

    var branch: ExpressBranch {
        switch self {
        case .swap: .swap
        case .onramp: .onramp
        }
    }
}

struct PendingTransaction {
    let type: PendingTransactionType

    let expressTransactionId: String
    let externalTxId: String?
    let externalTxURL: String?
    let provider: ExpressPendingTransactionRecord.Provider
    let date: Date

    let transactionStatus: PendingExpressTransactionStatus

    let refundedTokenItem: TokenItem?

    let statuses: [PendingExpressTransactionStatus]

    /// Average duration of transaction processing in seconds based on historical data.
    /// If nil, there is not enough data to calculate average duration.
    let averageDuration: TimeInterval?

    /// This parameter obtain from createdAt raw from status response
    let createdAt: Date?
}

final class CompoundPendingTransactionsManager: PendingExpressTransactionsManager {
    private let swapManager: PendingExpressTransactionsManager
    private let onrampManager: PendingExpressTransactionsManager

    init(
        swapManager: PendingExpressTransactionsManager,
        onrampManager: PendingExpressTransactionsManager
    ) {
        self.swapManager = swapManager
        self.onrampManager = onrampManager
    }

    var pendingTransactions: [PendingTransaction] {
        swapManager.pendingTransactions + onrampManager.pendingTransactions
    }

    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> {
        Publishers.CombineLatest(
            swapManager.pendingTransactionsPublisher,
            onrampManager.pendingTransactionsPublisher
        )
        .map { $0 + $1 }
        .eraseToAnyPublisher()
    }

    func hideTransaction(with id: String) {
        swapManager.hideTransaction(with: id)
        onrampManager.hideTransaction(with: id)
    }

    func pauseOnrampTransactionPolling() {
        onrampManager.pauseOnrampTransactionPolling()
    }

    func resumeOnrampTransactionPolling() {
        onrampManager.resumeOnrampTransactionPolling()
    }
}
