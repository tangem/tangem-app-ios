//
//  SendSuggestedDestinationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - View model

class SendSuggestedDestinationViewModel {
    let cellViewModels: [SendSuggestedDestinationViewCellModel]

    init(wallets: [SendSuggestedDestinationWallet], recentTransactions: [SendSuggestedDestinationTransactionRecord]) {
        var cellViewModels: [SendSuggestedDestinationViewCellModel] = []

        if !wallets.isEmpty {
            cellViewModels.append(.init(type: .header(title: Localization.sendRecipientWalletsTitle)))
            cellViewModels.append(contentsOf: wallets.map { .init(type: .wallet(wallet: $0)) })
        }

        if !recentTransactions.isEmpty {
            cellViewModels.append(.init(type: .header(title: Localization.sendRecentTransactions)))
            cellViewModels.append(contentsOf: recentTransactions.map { .init(type: .recentTransaction(record: $0)) })
        }

        self.cellViewModels = cellViewModels
    }
}

// MARK: - Cell model

class SendSuggestedDestinationViewCellModel: Identifiable {
    let type: `Type`

    init(type: Type) {
        self.type = type
    }
}

// MARK: - Helper types

extension SendSuggestedDestinationViewCellModel {
    enum `Type` {
        case header(title: String)
        case wallet(wallet: SendSuggestedDestinationWallet)
        case recentTransaction(record: SendSuggestedDestinationTransactionRecord)
    }
}

struct SendSuggestedDestinationWallet {
    let name: String
    let address: String
}

struct SendSuggestedDestinationTransactionRecord {
    let address: String
    let isOutgoing: Bool
    let description: String
}
