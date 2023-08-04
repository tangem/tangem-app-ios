//
//  FakeTransactionHistoryFactory.swift
//  Tangem
//
//  Created by Andrew Son on 26/06/23.
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
                destination: destination(for: .receive, address: "0x01230...3feed"),
                timeFormatted: "10:45",
//                date: today,
                transferAmount: "+443 \(currencyCode)",
                transactionType: .receive,
                status: .inProgress
            ),
            TransactionViewModel(
                destination: destination(for: .receive, address: "0x01230...3feed"),
                timeFormatted: "05:10",
//                date: calendar.date(byAdding: .hour, value: -4, to: today),
                transferAmount: "+50 \(currencyCode)",
                transactionType: .receive,
                status: .confirmed
            ),
            TransactionViewModel(
                destination: destination(for: .receive, address: "0x012...baced"),
                timeFormatted: "00:04",
//                date: calendar.date(byAdding: .hour, value: -5, to: today),
                transferAmount: "-0.5 \(currencyCode)",
                transactionType: .send,
                status: .inProgress
            ),
            TransactionViewModel(
                destination: destination(for: .receive, address: "0x0123...baced"),
                timeFormatted: "15:00",
//                date: yesterday,
                transferAmount: "-15 \(currencyCode)",
                transactionType: .send,
                status: .confirmed
            ),
            TransactionViewModel(
                destination: destination(for: .swap(type: .buy), address: "0x0123...baced"),
                timeFormatted: "10:23",
//                date: calendar.date(byAdding: .hour, value: -3, to: yesterday),
                transferAmount: "+0.000000532154 \(currencyCode)",
                transactionType: .swap(type: .buy),
                status: .inProgress
            ),
            TransactionViewModel(
                destination: destination(for: .swap(type: .sell), address: "0x0123...baced"),
                timeFormatted: "05:23",
//                date: calendar.date(byAdding: .hour, value: -8, to: yesterday),
                transferAmount: "-0.532154 \(currencyCode)",
                transactionType: .swap(type: .sell),
                status: .confirmed
            ),
            TransactionViewModel(
                destination: destination(for: .approval, address: "0x0123...baced"),
                timeFormatted: "18:32",
//                date: calendar.date(byAdding: .day, value: -6, to: yesterday),
                transferAmount: "-0.0012 \(currencyCode)",
                transactionType: .approval,
                status: .confirmed
            ),
            TransactionViewModel(
                destination: destination(for: .approval, address: "0x0123...baced"),
                timeFormatted: "18:82",
//                date: calendar.date(byAdding: .day, value: -10, to: yesterday),
                transferAmount: "-0.0012 \(currencyCode)",
                transactionType: .approval,
                status: .inProgress
            ),
        ]
    }

    private func destination(for transactionType: TransactionViewModel.TransactionType, address: String) -> String {
        transactionType.localizeDestination(for: address)
    }
}
