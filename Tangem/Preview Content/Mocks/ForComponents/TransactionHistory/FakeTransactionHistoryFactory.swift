//
//  FakeTransactionHistoryFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct FakeTransactionHistoryFactory {
    func createFakeTxs(currencyCode: String) -> [TransactionViewModel] {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        return [
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .receive, address: "0x01230...3feed"),
                timeFormatted: "10:45",
                transferAmount: "+443 \(currencyCode)",
                transactionType: .receive,
                status: .inProgress
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .receive, address: "0x01230...3feed"),
                timeFormatted: "05:10",
                transferAmount: "+50 \(currencyCode)",
                transactionType: .receive,
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .receive, address: "0x012...baced"),
                timeFormatted: "00:04",
                transferAmount: "-0.5 \(currencyCode)",
                transactionType: .send,
                status: .inProgress
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .receive, address: "0x0123...baced"),
                timeFormatted: "15:00",
                transferAmount: "-15 \(currencyCode)",
                transactionType: .send,
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .swap(type: .buy), address: "0x0123...baced"),
                timeFormatted: "10:23",
                transferAmount: "+0.000000532154 \(currencyCode)",
                transactionType: .swap(type: .buy),
                status: .inProgress
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .swap(type: .sell), address: "0x0123...baced"),
                timeFormatted: "05:23",
                transferAmount: "-0.532154 \(currencyCode)",
                transactionType: .swap(type: .sell),
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .approval, address: "0x0123...baced"),
                timeFormatted: "18:32",
                transferAmount: "-0.0012 \(currencyCode)",
                transactionType: .approval,
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .approval, address: "0x0123...baced"),
                timeFormatted: "18:82",
                transferAmount: "-0.0012 \(currencyCode)",
                transactionType: .approval,
                status: .inProgress
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .swap(type: .sell), address: "0x0123...baced"),
                timeFormatted: "03:23",
                transferAmount: "-0.2532154 \(currencyCode)",
                transactionType: .swap(type: .sell),
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .approval, address: "0x0123...baced"),
                timeFormatted: "18:42",
                transferAmount: "-0.0212 \(currencyCode)",
                transactionType: .approval,
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .approval, address: "0x0123...baced"),
                timeFormatted: "18:12",
                transferAmount: "-0.045642 \(currencyCode)",
                transactionType: .approval,
                status: .inProgress
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .swap(type: .sell), address: "0x0123...ba223ced"),
                timeFormatted: "15:23",
                transferAmount: "-1.532154 \(currencyCode)",
                transactionType: .swap(type: .sell),
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .approval, address: "0x01f3...baced"),
                timeFormatted: "18:32",
                transferAmount: "-0.0098725 \(currencyCode)",
                transactionType: .approval,
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .receive, address: "0x0123...baced"),
                timeFormatted: "18:00",
                transferAmount: "-0.1897912 \(currencyCode)",
                transactionType: .receive,
                status: .inProgress
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .swap(type: .sell), address: "0x0123...baced"),
                timeFormatted: "21:23",
                transferAmount: "-0.532154 \(currencyCode)",
                transactionType: .swap(type: .sell),
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .approval, address: "0x0123...baced"),
                timeFormatted: "19:32",
                transferAmount: "-9.0012 \(currencyCode)",
                transactionType: .approval,
                status: .confirmed
            ),
            TransactionViewModel(
                id: UUID().uuidString,
                destination: destination(for: .approval, address: "0x0123...baced"),
                timeFormatted: "18:30",
                transferAmount: "-0.789512 \(currencyCode)",
                transactionType: .approval,
                status: .inProgress
            ),
        ]
    }

    private func destination(for transactionType: TransactionViewModel.TransactionType, address: String) -> String {
        transactionType.localizeDestination(for: address)
    }
}
