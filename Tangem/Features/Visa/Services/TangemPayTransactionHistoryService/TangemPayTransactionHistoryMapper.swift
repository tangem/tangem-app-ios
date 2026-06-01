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

    func formatTransactions(
        _ transactions: [TangemPayTransactionHistoryResponse.Transaction],
        cardNameByCardId: [String: String]
    ) -> [TransactionListItem] {
        let transactionGroupsByDay = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.transactionDate)
        }

        return transactionGroupsByDay
            .sorted { $0.key > $1.key } // Start with most recent (e.g. 'Today')
            .enumerated()
            .compactMap { groupIndex, group in
                formatTransactionGroup(group, groupIndex: groupIndex, cardNameByCardId: cardNameByCardId)
            }
    }

    private func formatTransactionGroup(
        _ group: (Date, [TangemPayTransactionHistoryResponse.Transaction]),
        groupIndex: Int,
        cardNameByCardId: [String: String]
    ) -> TransactionListItem? {
        let (date, transactions) = group
        let items = transactions
            .sorted { first, second in
                first.transactionDate > second.transactionDate
            }
            .enumerated()
            .compactMap { index, item in
                formatTransactionRecord(
                    transaction: item,
                    index: groupIndex * 1000 + index,
                    cardNameByCardId: cardNameByCardId
                )
            }

        guard !items.isEmpty else { return nil }

        return TransactionListItem(
            header: formatter.string(from: date),
            items: items
        )
    }

    private func formatTransactionRecord(
        transaction: TangemPayTransactionHistoryResponse.Transaction,
        index: Int,
        cardNameByCardId: [String: String]
    ) -> TransactionViewModel? {
        let mapper = TangemPayTransactionRecordMapper(transaction: transaction)
        let amount = mapper.amount()
        let cardName = mapper.cardId().flatMap { cardNameByCardId[$0] }
        return TransactionViewModel(
            hash: transaction.id,
            index: index,
            interactionAddress: .custom(message: mapper.categoryName(detailed: false)),
            timeFormatted: mapper.time(),
            amount: amount,
            value: amount,
            currencyCode: "",
            isOutgoing: mapper.isOutgoing(),
            transactionType: mapper.type(),
            status: mapper.status(),
            isFromYieldContract: false,
            cardName: cardName
        )
    }
}

extension TangemPayTransactionRecord {
    var transactionDate: Date {
        switch record {
        case .spend(let spend): spend.transactionDate
        case .collateral(let collateral): collateral.postedAt
        case .payment(let payment): payment.postedAt
        case .fee(let fee): fee.postedAt
        }
    }
}

extension TangemPayTransactionHistoryResponse.Spend {
    /// Refunds (negative-amount spends) are dated by when they posted, not when they were authorized.
    var transactionDate: Date {
        amount < 0 ? (postedAt ?? authorizedAt) : authorizedAt
    }
}
