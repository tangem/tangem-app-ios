//
//  TransactionsHistoryUtility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TransactionsHistoryUtility {
    func convertToTransactionRecords(_ transactions: [Transaction], for wallet: Wallet) -> [TransactionRecord] {
        transactions.compactMap { convertToTransactionRecord($0, for: wallet) }
    }

    func convertToTransactionRecord(_ transaction: Transaction, for wallet: Wallet) -> TransactionRecord? {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        guard let date = transaction.date else {
            return nil
        }

        let direction: TransactionRecord.Direction = wallet.addresses.contains(where: { $0.value == transaction.destinationAddress }) ? .incoming : .outgoing
        return .init(
            amountType: transaction.amount.type,
            destination: transaction.destinationAddress,
            time: timeFormatter.string(from: date),
            transferAmount: "\(direction.amountPrefix)\(transaction.amount.string(with: 8))",
            canBePushed: false,
            direction: direction,
            status: .init(transaction.status)
        )
    }

    func makeTransactionListItems(from transactions: [TransactionRecord]) -> [TransactionListItem] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        let calendar = Calendar.current

        var controlDate: Date!
        var txListItems = [TransactionListItem]()
        var controlDateTxs = [TransactionRecord]()
        transactions.forEach { tx in
            guard let recordDate = tx.date else {
                return
            }

            if controlDate == .none {
                controlDate = recordDate
                controlDateTxs.append(tx)
                return
            }

            if calendar.isDate(recordDate, inSameDayAs: controlDate) {
                controlDateTxs.append(tx)
                return
            }

            let listItem = TransactionListItem(
                header: dateFormatter.string(from: controlDate),
                items: controlDateTxs
            )
            txListItems.append(listItem)
            controlDate = recordDate
            controlDateTxs = []
        }

        if controlDate != .none, !controlDateTxs.isEmpty {
            txListItems.append(TransactionListItem(
                header: dateFormatter.string(from: controlDate),
                items: controlDateTxs
            ))
        }

        txListItems.forEach {
            let set = Set($0.items)
            assert(set.count == $0.items.count, "Contain duplicates... In \($0.header)")
        }

        return txListItems
    }
}
