//
//  TangemPayTransactionHistoryMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa

// [REDACTED_TODO_COMMENT]
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
                formatTransactionRecord(item.record, index: groupIndex * 1000 + index)
            }

        guard !items.isEmpty else { return nil }

        return TransactionListItem(
            header: formatter.string(from: date),
            items: items
        )
    }

    private func formatTransactionRecord(
        _ record: TangemPayTransactionHistoryResponse.Record,
        index: Int
    ) -> TransactionViewModel? {
        switch record {
        case .spend(let spend):
            formatSpend(spend, index: index)
        case .collateral:
            nil
        case .payment(let payment):
            formatPayment(payment, index: index)
        case .fee(let fee):
            formatFee(fee, index: index)
        }
    }

    private func formatSpend(
        _ spend: TangemPayTransactionHistoryResponse.Spend,
        index: Int
    ) -> TransactionViewModel {
        TransactionViewModel(
            hash: "N/A",
            index: index,
            interactionAddress: .custom(message: spend.enrichedMerchantCategory ?? spend.merchantCategory ?? spend.merchantCategoryCode),
            timeFormatted: (spend.postedAt ?? spend.authorizedAt).formatted(date: .omitted, time: .shortened),
            amount: "\(spend.isDeclined ? "" : "–")$\(spend.amount)",
            isOutgoing: true,
            transactionType: .tangemPay(
                name: spend.enrichedMerchantName ?? spend.merchantName ?? "Card payment",
                icon: spend.enrichedMerchantIcon,
                isDeclined: spend.isDeclined
            ),
            status: .confirmed
        )
    }

    private func formatPayment(
        _ payment: TangemPayTransactionHistoryResponse.Payment,
        index: Int
    ) -> TransactionViewModel {
        let isOutgoing = payment.amount < 0

        return TransactionViewModel(
            hash: "N/A",
            index: index,
            interactionAddress: .custom(message: "Transfers"),
            timeFormatted: payment.postedAt.formatted(date: .omitted, time: .shortened),
            amount: "$\(payment.amount)",
            isOutgoing: isOutgoing,
            transactionType: .tangemPayTransfer(name: isOutgoing ? "Withdraw" : "Deposit"),
            status: .confirmed
        )
    }

    private func formatFee(
        _ fee: TangemPayTransactionHistoryResponse.Fee,
        index: Int
    ) -> TransactionViewModel {
        TransactionViewModel(
            hash: "N/A",
            index: index,
            interactionAddress: .custom(message: "Service fees"),
            timeFormatted: fee.postedAt.formatted(date: .omitted, time: .shortened),
            amount: "–$\(fee.amount)",
            isOutgoing: true,
            transactionType: .tangemPay(name: "Fee", icon: nil, isDeclined: false),
            status: .confirmed
        )
    }
}
