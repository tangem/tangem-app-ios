//
//  OnrampStatusScreenViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import UIKit
import TangemAssets
import TangemExpress
import TangemFoundation
import TangemLocalization
import TangemUI

final class OnrampStatusScreenViewModel: ObservableObject {
    @Published private(set) var state: State = .make(status: nil)
    @Published private(set) var cryptoAmount: String?
    @Published private(set) var fiatAmount: String?
    @Published private(set) var providerName: String?
    @Published private(set) var providerIconURL: URL?
    @Published private(set) var externalTxId: String?

    private let tokenItem: TokenItem
    private let pendingTransactionsManager: PendingExpressTransactionsManager
    private let expressStatusPollingHelper: ExpressStatusPollingHelper
    private let balanceFormatter = BalanceFormatter()
    private var bag: Set<AnyCancellable> = []

    init(
        tokenItem: TokenItem,
        amountInput: OnrampAmountInput,
        providersInput: OnrampProvidersInput,
        statusInput: OnrampStatusInput,
        pendingTransactionsManager: PendingExpressTransactionsManager,
        expressStatusPollingHelper: ExpressStatusPollingHelper
    ) {
        self.tokenItem = tokenItem
        self.pendingTransactionsManager = pendingTransactionsManager
        self.expressStatusPollingHelper = expressStatusPollingHelper

        bind(amountInput: amountInput, providersInput: providersInput, statusInput: statusInput)
    }

    func copyTransactionId() {
        guard let externalTxId else {
            return
        }

        UIPasteboard.general.string = externalTxId

        let snackbar = TangemSnackbar(title: Localization.expressTransactionIdCopied)
            .icon(DesignSystem.Icons.Success.regular20)
            .iconColor(DesignSystem.Color.iconAccentBlue)
        Toast(view: snackbar).present(layout: .top(padding: 12), type: .temporary())
    }
}

// MARK: - Private

private extension OnrampStatusScreenViewModel {
    func bind(amountInput: OnrampAmountInput, providersInput: OnrampProvidersInput, statusInput: OnrampStatusInput) {
        Publishers.CombineLatest(amountInput.amountPublisher, amountInput.fiatCurrencyPublisher)
            .map { [balanceFormatter] amount, currency -> String? in
                guard let amount, let currency else {
                    return nil
                }

                let options = BalanceFormattingOptions(
                    minFractionDigits: currency.precision,
                    maxFractionDigits: currency.precision,
                    formatEpsilonAsLowestRepresentableValue: false,
                    roundingType: .default(roundingMode: .plain, scale: currency.precision)
                )

                return balanceFormatter.formatFiatBalance(amount, currencyCode: currency.identity.code, formattingOptions: options)
            }
            .receiveOnMain()
            .assign(to: &$fiatAmount)

        providersInput.selectedOnrampProviderPublisher
            .compactMap { $0?.value }
            .first()
            .receiveOnMain()
            .sink { [weak self] provider in
                self?.update(provider: provider)
            }
            .store(in: &bag)

        Publishers.CombineLatest(pendingTransactionsManager.pendingTransactionsPublisher, statusInput.expressTransactionId)
            .compactMap { pendingTransactions, transactionId in
                pendingTransactions.first(where: { $0.expressTransactionId == transactionId })
            }
            .receiveOnMain()
            .sink { [weak self] pendingTransaction in
                self?.update(pendingTransaction: pendingTransaction)
            }
            .store(in: &bag)
    }

    func update(provider: OnrampProvider) {
        providerName = provider.provider.name
        providerIconURL = provider.provider.imageURL

        cryptoAmount = provider.quote.map { quote in
            let formatted = balanceFormatter.formatCryptoBalance(quote.expectedAmount, tokenItem: tokenItem)
            return "\(AppConstants.tildeSign) \(formatted)"
        }
    }

    func update(pendingTransaction: PendingTransaction) {
        state = .make(status: pendingTransaction.transactionStatus)
        externalTxId = pendingTransaction.externalTxId
        providerName = pendingTransaction.provider.name
        providerIconURL = pendingTransaction.provider.iconURL

        if case .onramp(_, _, let destination) = pendingTransaction.type, !destination.amountString.isEmpty {
            cryptoAmount = balanceFormatter.formatCryptoBalance(destination.amount, tokenItem: tokenItem)
        }
    }
}

// MARK: - State

extension OnrampStatusScreenViewModel {
    struct State: Equatable {
        let title: String
        let glyph: StatusIcon.Glyph
        let appearance: StatusScreenAppearance

        static func make(status: PendingExpressTransactionStatus?) -> State {
            let status = status ?? .awaitingDeposit

            switch status {
            case .created, .awaitingDeposit, .confirming, .buying, .exchanging, .sendingToUser, .refunding:
                return State(title: status.activeStatusTitle, glyph: .pending, appearance: .info)
            case .awaitingHash, .verificationRequired:
                return State(title: status.activeStatusTitle, glyph: .warning, appearance: .warning)
            case .finished:
                return State(title: Localization.expressExchangeStatusBought, glyph: .checkmark, appearance: .success)
            case .failed, .unknown, .txFailed, .expired, .paused, .refunded:
                return State(title: status.activeStatusTitle, glyph: .heartBroken, appearance: .error)
            }
        }
    }
}
