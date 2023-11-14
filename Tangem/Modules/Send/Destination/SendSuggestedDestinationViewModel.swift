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
    private(set) var cellViewModels: [SendSuggestedDestinationViewCellModel] = []

    private let tapAction: (SendSuggestedDestination) -> Void

    init(
        wallets: [SendSuggestedDestinationWallet],
        recentTransactions: [SendSuggestedDestinationTransactionRecord],
        tapAction: @escaping (SendSuggestedDestination) -> Void
    ) {
        self.tapAction = tapAction

        var cellViewModels: [SendSuggestedDestinationViewCellModel] = []

        if !wallets.isEmpty {
            cellViewModels.append(SendSuggestedDestinationViewCellModel(type: .header(title: Localization.sendRecipientWalletsTitle), tapAction: nil))
            cellViewModels.append(
                contentsOf: wallets.map { [weak self] wallet in
                    SendSuggestedDestinationViewCellModel(
                        type: .wallet(wallet: wallet),
                        tapAction: {
                            self?.tapAction(SendSuggestedDestination(address: wallet.address, additionalField: nil))
                        }
                    )
                }
            )
        }

        if !recentTransactions.isEmpty {
            cellViewModels.append(SendSuggestedDestinationViewCellModel(type: .header(title: Localization.sendRecentTransactions), tapAction: nil))
            cellViewModels.append(
                contentsOf: recentTransactions.map { [weak self] record in
                    SendSuggestedDestinationViewCellModel(
                        type: .recentTransaction(record: record),
                        tapAction: {
                            self?.tapAction(SendSuggestedDestination(address: record.address, additionalField: record.additionalField))
                        }
                    )
                }
            )
        }

        self.cellViewModels = cellViewModels
    }
}

// MARK: - Cell model

struct SendSuggestedDestinationViewCellModel: Identifiable {
    let id = UUID()

    let type: `Type`
    let tapAction: (() -> Void)?

    init(type: Type, tapAction: (() -> Void)?) {
        self.type = type
        self.tapAction = tapAction
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

struct SendSuggestedDestination {
    let address: String
    let additionalField: String?
}

struct SendSuggestedDestinationWallet {
    let name: String
    let address: String
}

struct SendSuggestedDestinationTransactionRecord {
    let address: String
    let additionalField: String?
    let isOutgoing: Bool
    let description: String
}
