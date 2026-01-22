//
//  SendDestinationSuggestedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts
import TangemLocalization

// MARK: - View model

class SendDestinationSuggestedViewModel {
    var suggestedWalletsHeader: String {
        if suggestedWallets.contains(where: { $0.wallet.account != nil }) {
            return Localization.commonAccounts
        }

        return Localization.sendRecipientWalletsTitle
    }

    private(set) var suggestedWallets: [Wallet] = []
    private(set) var suggestedRecentTransaction: [RecentTransaction] = []

    private let tapAction: (SendDestinationSuggested) -> Void

    init(
        wallets: [SendDestinationSuggestedWallet],
        recentTransactions: [SendDestinationSuggestedTransactionRecord],
        tapAction: @escaping (SendDestinationSuggested) -> Void
    ) {
        self.tapAction = tapAction

        suggestedWallets = wallets.map { wallet in
            Wallet(
                id: wallet.address,
                addressIconViewModel: AddressIconViewModel(address: wallet.address),
                wallet: wallet
            ) { [weak self] in
                self?.tapAction(SendDestinationSuggested(
                    address: wallet.address,
                    additionalField: nil,
                    type: .otherWallet,
                    accountModelAnalyticsProvider: wallet.accountModelAnalyticsProvider,
                    tokenHeader: wallet.tokenHeader
                ))
            }
        }

        suggestedRecentTransaction = recentTransactions.map { record in
            RecentTransaction(
                id: record.id,
                addressIconViewModel: AddressIconViewModel(address: record.address),
                record: record
            ) { [weak self] in
                self?.tapAction(SendDestinationSuggested(
                    address: record.address,
                    additionalField: record.additionalField,
                    type: .recentAddress,
                    // Nil because we dont have account info in recent addreses
                    accountModelAnalyticsProvider: nil,
                    tokenHeader: nil
                ))
            }
        }
    }
}

// MARK: - UI view models

extension SendDestinationSuggestedViewModel {
    struct RecentTransaction: Identifiable {
        let id: String
        let addressIconViewModel: AddressIconViewModel
        let record: SendDestinationSuggestedTransactionRecord
        let action: () -> Void
    }

    struct Wallet: Identifiable {
        let id: String
        let addressIconViewModel: AddressIconViewModel
        let wallet: SendDestinationSuggestedWallet
        let action: () -> Void
    }
}

// MARK: - SendDestinationSuggested (selection result model)

struct SendDestinationSuggested {
    let address: String
    let additionalField: String?
    let type: DestinationType
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    let tokenHeader: ExpressInteractorTokenHeader?

    enum DestinationType {
        case otherWallet
        case recentAddress
    }
}

// MARK: - SuggestedWallet (User's wallets)

struct SendDestinationSuggestedWallet {
    let name: String
    let address: String
    let account: Account?
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    let tokenHeader: ExpressInteractorTokenHeader?

    struct Account {
        let icon: AccountIconView.ViewData
        let name: String
    }

    init(
        name: String,
        address: String,
        account: Account?,
        accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?,
        tokenHeader: ExpressInteractorTokenHeader?
    ) {
        self.name = name
        self.address = address
        self.account = account
        self.accountModelAnalyticsProvider = accountModelAnalyticsProvider
        self.tokenHeader = tokenHeader
    }
}

// MARK: - TransactionRecord (History)

struct SendDestinationSuggestedTransactionRecord {
    let id: String
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
