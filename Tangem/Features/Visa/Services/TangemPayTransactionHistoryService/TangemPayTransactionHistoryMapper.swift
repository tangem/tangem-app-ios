//
//  TangemPayTransactionHistoryMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemVisa
import TangemPay

struct TangemPayTransactionHistoryMapper {
    private let calendar: Calendar = .current
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.locale = .current
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    func formatTransactions(_ transactions: [TangemPayTransactionHistoryResponse.Transaction]) -> [TransactionListItem] {
        let transactionGroupsByDay = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.transactionDate)
        }

        return transactionGroupsByDay
            .sorted { $0.key > $1.key } // Start with most recent (e.g. 'Today')
            .enumerated()
            .compactMap { groupIndex, group in
                formatTransactionGroup(group, groupIndex: groupIndex)
            }
    }

    private func formatTransactionGroup(
        _ group: (Date, [TangemPayTransactionHistoryResponse.Transaction]),
        groupIndex: Int
    ) -> TransactionListItem? {
        let (date, transactions) = group
        let items = transactions
            .sorted { first, second in
                first.transactionDate > second.transactionDate
            }
            .enumerated()
            .compactMap { index, item in
                formatTransactionRecord(transaction: item, index: groupIndex * 1000 + index)
            }

        guard !items.isEmpty else { return nil }

        return TransactionListItem(
            header: formatter.string(from: date),
            items: items
        )
    }

    private func formatTransactionRecord(
        transaction: TangemPayTransactionHistoryResponse.Transaction,
        index: Int
    ) -> TransactionViewModel? {
        let mapper = TangemPayTransactionRecordMapper(transaction: transaction)
        return TransactionViewModel(
            hash: transaction.id,
            index: index,
            interactionAddress: .custom(message: mapper.categoryName()),
            timeFormatted: mapper.time(),
            amount: mapper.amount(),
            isOutgoing: mapper.isOutgoing(),
            transactionType: mapper.type(),
            status: mapper.status(),
            isFromYieldContract: false
        )
    }
}
