//
//  TransactionHistoryMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct TransactionHistoryMapper {
    let walletAddress: String

    func mapTransactionListItem(from records: [TransactionRecord]) -> [TransactionListItem] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        let calendar = Calendar.current

        var controlDate: Date!
        var txListItems = [TransactionListItem]()
        var controlDateTxs = [TransactionViewModel]()
        records.forEach { record in
            // Check if this is first transaction. If so add to list.
            if controlDate == nil {
                controlDate = record.date
                let viewModel = mapTransactionViewModel(record)
                controlDateTxs.append(viewModel)
                return
            }

            // If this current transaction was in the same day - add to list
            // otherwise create day group
            if calendar.isDate(record.date, inSameDayAs: controlDate) {
                let viewModel = mapTransactionViewModel(record)
                controlDateTxs.append(viewModel)
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
            controlDate = record.date
            let viewModel = mapTransactionViewModel(record)
            controlDateTxs = [viewModel]
        }

        // Transactions in the last day group won't be added in forEach loop, so we need to
        // check if there are any. If so - create a list of transactions for the last day
        if controlDate != nil, !controlDateTxs.isEmpty {
            txListItems.append(TransactionListItem(
                header: dateFormatter.string(from: controlDate),
                items: controlDateTxs
            ))
        }

        return txListItems
    }

    func mapTransactionViewModel(_ record: TransactionRecord) -> TransactionViewModel {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let type = transactionType(from: record)

        return TransactionViewModel(
            destination: destination(from: record),
            timeFormatted: timeFormatter.string(from: record.date),
            transferAmount: "\(type.amountPrefix)\(transferAmount(from: record))",
            transactionType: type,
            status: record.status == .confirmed ? .confirmed : .inProgress
        )
    }

    func transferAmount(from record: TransactionRecord) -> String {
        switch record.type {
        case .send:
            switch record.destination {
            case .single(let destination):
                return destination.amount.string(with: 2)
            case .multiple(let destinations):
                // [REDACTED_TODO_COMMENT]
                return destinations.first?.amount.string(with: 2) ?? ""
            }
        case .receive:
            switch record.source {
            case .single(let source):
                return source.amount.string(with: 2)
            case .multiple(let destinations):
                return destinations.first?.amount.string(with: 2) ?? ""
            }
        }
    }

    func destination(from record: TransactionRecord) -> String {
        switch record.type {
        case .send:
            switch record.destination {
            case .single(let destination):
                return destination.address.string
            case .multiple(let destinations):
                // [REDACTED_TODO_COMMENT]
                return destinations.first(where: { $0.address.string != walletAddress })?.address.string ?? ""
            }
        case .receive:
            switch record.source {
            case .single(let source):
                return source.address
            case .multiple(let sources):
                return sources.first(where: { $0.address != walletAddress })?.address ?? ""
            }
        }
    }

    func transactionType(from record: TransactionRecord) -> TransactionViewModel.TransactionType {
        switch record.type {
        case .receive:
            return .receive
        case .send:
            return .send
        }
    }
}
