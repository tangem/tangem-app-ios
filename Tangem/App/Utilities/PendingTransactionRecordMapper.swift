//
//  PendingTransactionRecordMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal

struct PendingTransactionRecordMapper {
    private let formatter: BalanceFormatter
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    init(formatter: BalanceFormatter) {
        self.formatter = formatter
    }

    func mapToTransactionRecord(pending: PendingTransactionRecord) -> TransactionRecord {
        TransactionRecord(
            hash: pending.hash,
            index: 0,
            source: .single(.init(address: pending.source, amount: pending.amount.value)),
            destination: .single(.init(address: .user(pending.destination), amount: pending.amount.value)),
            fee: pending.fee,
            status: .unconfirmed,
            isOutgoing: !pending.isIncoming,
            type: .transfer,
            date: pending.date,
            tokenTransfers: nil
        )
    }

    func mapToTransactionViewModel(_ transaction: PendingTransactionRecord) -> TransactionViewModel {
        let timeFormatted = timeFormatter.string(from: transaction.date)

        return TransactionViewModel(
            hash: transaction.hash,
            index: 0,
            interactionAddress: interactionAddress(for: transaction),
            timeFormatted: timeFormatted,
            amount: amount(for: transaction),
            isOutgoing: !transaction.isIncoming,
            transactionType: transactionType(for: transaction),
            status: .inProgress
        )
    }

    func amount(for transaction: PendingTransactionRecord) -> String {
        formatter.formatCryptoBalance(
            transaction.amount.value,
            currencyCode: transaction.amount.currencySymbol
        )
    }

    func interactionAddress(for transaction: PendingTransactionRecord) -> TransactionViewModel.InteractionAddressType {
        guard transaction.amount.value > 0 else {
            return .contract(transaction.destination)
        }

        if transaction.isIncoming {
            return .user(transaction.source)
        }

        return .user(transaction.destination)
    }

    private func transactionType(for transaction: PendingTransactionRecord) -> TransactionViewModel.TransactionType {
        switch transaction.transactionType {
        case .transfer:
            return .transfer
        case .stake:
            return .stake
        case .operation:
            return .operation(name: Localization.transactionHistoryOperation)
        }
    }
}
