//
//  TransactionHistoryMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TransactionHistoryMapper {
    func convertToTransactionRecords(_ transactions: [Transaction], for addresses: [BlockchainSdk.Address]) -> [TransactionRecord] {
        transactions.compactMap { convertToTransactionRecord($0, for: addresses) }
    }

    func convertToTransactionRecord(_ transaction: Transaction, for addresses: [BlockchainSdk.Address]) -> TransactionRecord? {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        guard let date = transaction.date else {
            return nil
        }

        let direction: TransactionRecord.Direction = addresses.contains(where: { $0.value == transaction.destinationAddress }) ? .incoming : .outgoing
        return .init(
            amountType: transaction.amount.type,
            destination: AddressFormatter(address: transaction.destinationAddress).truncated(),
            timeFormatted: timeFormatter.string(from: date),
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

            // Check if this is first transaction. If so add to list.
            if controlDate == nil {
                controlDate = recordDate
                controlDateTxs.append(tx)
                return
            }

            // If this current transaction was in the same day - add to list
            // otherwise create day group
            if calendar.isDate(recordDate, inSameDayAs: controlDate) {
                controlDateTxs.append(tx)
                return
            }

            // Create transaction list item grouped by day with relative date formatting
            // all transaction from previous date will be added to list excluding current transaction
            let listItem = TransactionListItem(
                header: dateFormatter.string(from: controlDate),
                items: controlDateTxs
            )
            txListItems.append(listItem)

            // Set current transaction date as new control date and create new list with current transaction
            controlDate = recordDate
            controlDateTxs = [tx]
        }

        // Transactions in the last day group won't be added in forEach loop, so we need to
        // check if there are any. If so - create a list of transactions for the last day
        if controlDate != nil, !controlDateTxs.isEmpty {
            txListItems.append(TransactionListItem(
                header: dateFormatter.string(from: controlDate),
                items: controlDateTxs
            ))
        }

        #if DEBUG
        // Validate that groups doesn't contain duplicated
        txListItems.forEach {
            let set = Set($0.items)
            assert(set.count == $0.items.count, "Contain duplicates... In \($0.header)")
        }
        #endif

        return txListItems
    }
}
