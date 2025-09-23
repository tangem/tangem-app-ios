//
//  SendDestinationSuggestedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

// MARK: - View model

class SendDestinationSuggestedViewModel {
    private(set) var cellViewModels: [CellModel] = []

    private let tapAction: (SendDestinationSuggested) -> Void

    init(
        wallets: [SendDestinationSuggestedWallet],
        recentTransactions: [SendDestinationSuggestedTransactionRecord],
        tapAction: @escaping (SendDestinationSuggested) -> Void
    ) {
        self.tapAction = tapAction

        var cellViewModels: [CellModel] = []

        if !wallets.isEmpty {
            cellViewModels.append(CellModel(type: .header(title: Localization.sendRecipientWalletsTitle), tapAction: nil))
            cellViewModels.append(
                contentsOf: wallets.map { [weak self] wallet in
                    CellModel(
                        type: .wallet(wallet: wallet, addressIconViewModel: AddressIconViewModel(address: wallet.address)),
                        tapAction: {
                            self?.tapAction(SendDestinationSuggested(address: wallet.address, additionalField: nil, type: .otherWallet))
                        }
                    )
                }
            )
        }

        if !recentTransactions.isEmpty {
            cellViewModels.append(CellModel(type: .header(title: Localization.sendRecentTransactions), tapAction: nil))
            cellViewModels.append(
                contentsOf: recentTransactions.map { [weak self] record in
                    CellModel(
                        type: .recentTransaction(record: record, addressIconViewModel: AddressIconViewModel(address: record.address)),
                        tapAction: {
                            self?.tapAction(SendDestinationSuggested(address: record.address, additionalField: record.additionalField, type: .recentAddress))
                        }
                    )
                }
            )
        }

        self.cellViewModels = cellViewModels
    }
}

// MARK: - Cell model

extension SendDestinationSuggestedViewModel {
    struct CellModel: Identifiable {
        let id = UUID()

        let type: `Type`
        let tapAction: (() -> Void)?
    }
}

// MARK: - Helper types

extension SendDestinationSuggestedViewModel.CellModel {
    enum `Type` {
        case header(title: String)
        case wallet(wallet: SendDestinationSuggestedWallet, addressIconViewModel: AddressIconViewModel)
        case recentTransaction(record: SendDestinationSuggestedTransactionRecord, addressIconViewModel: AddressIconViewModel)
    }
}

struct SendDestinationSuggested {
    let address: String
    let additionalField: String?
    let type: DestinationType
}

extension SendDestinationSuggested {
    enum DestinationType {
        case otherWallet
        case recentAddress
    }
}

struct SendDestinationSuggestedWallet {
    let name: String
    let address: String
}

struct SendDestinationSuggestedTransactionRecord {
    let address: String
    let additionalField: String?
    let isOutgoing: Bool
    let date: Date
    let amountFormatted: String
    let dateFormatted: String
}

extension SendDestinationSuggestedTransactionRecord {
    func description(_ amount: String) -> String {
        "\(amount), \(dateFormatted)"
    }
}
