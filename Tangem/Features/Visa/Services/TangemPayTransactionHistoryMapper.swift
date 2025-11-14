//
//  TangemPayTransactionHistoryMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemLocalization

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
        case .collateral(let collateral):
            formatCollateral(collateral, index: index)
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
        let sign: String
        if spend.amount == 0 || spend.isDeclined {
            sign = ""
        } else {
            sign = "–"
        }

        return TransactionViewModel(
            hash: "N/A",
            index: index,
            interactionAddress: .custom(
                message: spend.enrichedMerchantCategory
                    ?? spend.merchantCategory
                    ?? spend.merchantCategoryCode
                    ?? Localization.tangemPayOther
            ),
            timeFormatted: spend.authorizedAt.formatted(date: .omitted, time: .shortened),
            amount: "\(sign)$\(abs(spend.amount))",
            isOutgoing: true,
            transactionType: .tangemPay(
                name: spend.enrichedMerchantName ?? spend.merchantName ?? Localization.tangempayCardDetailsTitle,
                icon: spend.enrichedMerchantIcon,
                isDeclined: spend.isDeclined
            ),
            status: .confirmed
        )
    }

    private func formatCollateral(
        _ collateral: TangemPayTransactionHistoryResponse.Collateral,
        index: Int
    ) -> TransactionViewModel {
        TransactionViewModel(
            hash: "N/A",
            index: index,
            interactionAddress: .custom(message: Localization.commonTransfer),
            timeFormatted: (collateral.postedAt).formatted(date: .omitted, time: .shortened),
            amount: "+$\(abs(collateral.amount))",
            isOutgoing: false,
            transactionType: .tangemPayTransfer(name: Localization.tangemPayDeposit),
            status: .confirmed
        )
    }

    private func formatPayment(
        _ payment: TangemPayTransactionHistoryResponse.Payment,
        index: Int
    ) -> TransactionViewModel {
        TransactionViewModel(
            hash: "N/A",
            index: index,
            interactionAddress: .custom(message: Localization.commonTransfer),
            timeFormatted: payment.postedAt.formatted(date: .omitted, time: .shortened),
            amount: "–$\(abs(payment.amount))",
            isOutgoing: true,
            transactionType: .tangemPayTransfer(name: Localization.tangemPayWithdrawal),
            status: payment.status.status
        )
    }

    private func formatFee(
        _ fee: TangemPayTransactionHistoryResponse.Fee,
        index: Int
    ) -> TransactionViewModel {
        TransactionViewModel(
            hash: "N/A",
            index: index,
            interactionAddress: .custom(message: fee.description ?? Localization.tangemPayFeeSubtitle),
            timeFormatted: fee.postedAt.formatted(date: .omitted, time: .shortened),
            amount: "–$\(abs(fee.amount))",
            isOutgoing: true,
            transactionType: .tangemPay(name: Localization.tangemPayFeeTitle, icon: nil, isDeclined: false),
            status: .confirmed
        )
    }
}

private extension TangemPayTransactionHistoryResponse.PaymentStatus {
    var status: TransactionViewModel.Status {
        switch self {
        case .pending:
            .inProgress
        case .completed:
            .confirmed
        }
    }
}
