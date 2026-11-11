//
//  LendingWithdrawConfirmViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemFoundation
import struct TangemUIUtils.AlertBinder

@MainActor
final class LendingWithdrawConfirmViewModel: ObservableObject {
    typealias StateModel = LendingWithdrawConfirmContentView.StateModel
    typealias Action = LendingWithdrawConfirmContentView.Action

    @Published private(set) var state: StateModel
    @Published var alert: AlertBinder?

    private(set) var withdrawTask: Task<Void, Never>?

    private let model: LendingWithdrawModel
    private let sourceToken: SendTransferableToken
    private let mailDataBuilder: SendMailDataBuilder
    private let analyticsLogger: LendingAnalyticsLogger
    private let alertBuilder = LendingFailureAlertBuilder(failureMessage: LendingWithdrawText.failure)
    private weak var router: LendingWithdrawConfirmRoutable?
    private var bag: Set<AnyCancellable> = []

    init(
        model: LendingWithdrawModel,
        sourceToken: SendTransferableToken,
        mailDataBuilder: SendMailDataBuilder,
        analyticsLogger: LendingAnalyticsLogger,
        router: LendingWithdrawConfirmRoutable?
    ) {
        self.model = model
        self.sourceToken = sourceToken
        self.mailDataBuilder = mailDataBuilder
        self.analyticsLogger = analyticsLogger
        self.router = router

        state = StateModel(
            tokenIconInfo: TokenIconInfoBuilder().build(from: sourceToken.tokenItem, isCustom: sourceToken.isCustom),
            fiatAmount: BalanceFormatter.defaultEmptyBalanceString,
            cryptoAmount: BalanceFormatter.defaultEmptyBalanceString,
            fee: .loading,
            canChangeFeeSpeed: false,
            signingActionButtonType: sourceToken.signingActionButtonType,
            isWithdrawEnabled: false,
            isWithdrawing: false
        )

        bind()
    }

    func handle(_ action: Action) {
        switch action {
        case .close:
            router?.closeWithdrawal()
        case .fee:
            router?.openFeeSelector()
        case .retryFee:
            model.updateFees()
        case .openURL(let url):
            router?.openURL(url)
        case .withdraw:
            withdraw()
        }
    }
}

// MARK: - Private

private extension LendingWithdrawConfirmViewModel {
    func bind() {
        model.sourceAmountPublisher
            .map(\.value)
            .receiveOnMain()
            .sink { [weak self] amount in
                self?.amountDidChange(amount)
            }
            .store(in: &bag)

        model.selectedFeePublisher
            .receiveOnMain()
            .sink { [weak self] tokenFee in
                self?.state.fee = LendingFee(tokenFee)
            }
            .store(in: &bag)

        model.supportFeeSelectionPublisher
            .receiveOnMain()
            .sink { [weak self] canChangeFeeSpeed in
                self?.state.canChangeFeeSpeed = canChangeFeeSpeed
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            model.isFeeCoveredPublisher,
            model.sourceAmountPublisher.map { $0.value?.crypto },
            model.availableToWithdrawPublisher
        )
        .map { isFeeCovered, amount, available in
            guard isFeeCovered, let amount else {
                return false
            }

            return amount <= available
        }
        .removeDuplicates()
        .receiveOnMain()
        .sink { [weak self] isWithdrawEnabled in
            self?.state.isWithdrawEnabled = isWithdrawEnabled
        }
        .store(in: &bag)

        model.isWithdrawingPublisher
            .removeDuplicates()
            .receiveOnMain()
            .sink { [weak self] isWithdrawing in
                self?.state.isWithdrawing = isWithdrawing
            }
            .store(in: &bag)
    }

    func amountDidChange(_ amount: SendAmount?) {
        let tokenItem = sourceToken.tokenItem
        let cryptoFormatter = SendCryptoValueFormatter(decimals: tokenItem.decimalCount, currencySymbol: tokenItem.currencySymbol, trimFractions: true)

        state.cryptoAmount = amount?.crypto.flatMap(cryptoFormatter.string(from:)) ?? BalanceFormatter.defaultEmptyBalanceString
        state.fiatAmount = BalanceFormatter().formatFiatBalance(amount?.fiat)
    }

    func withdraw() {
        guard withdrawTask == nil else {
            return
        }

        withdrawTask = Task { @MainActor [weak self] in
            await self?.performWithdrawal()
            self?.withdrawTask = nil
        }
    }

    @MainActor
    func performWithdrawal() async {
        do {
            _ = try await model.withdraw()
            analyticsLogger.logSent(amount: model.sourceAmount.value?.crypto)
            router?.withdrawalDidSend()
        } catch is CancellationError {
            return
        } catch let error as TransactionDispatcherResult.Error {
            analyticsLogger.logFailure(error)
            alert = alertBuilder.makeAlert(
                for: error,
                retryFee: { [weak self] in self?.model.updateFees() },
                openSupport: { [weak self] transaction, error in
                    self?.analyticsLogger.logErrorPopupAction(.support)
                    self?.openSupport(transaction: transaction, error: error)
                },
                close: { [analyticsLogger] in analyticsLogger.logErrorPopupAction(.close) }
            )
        } catch {
            AppLogger.error(error: error)
            alert = error.alertBinder
        }
    }

    func openSupport(transaction: TransactionDispatcherTransactionType, error: SendTxError) {
        guard case .transfer(let transaction) = transaction else {
            return
        }

        do {
            let supportData = try mailDataBuilder.makeSupportData(transaction: model.supportTransaction(for: transaction), error: error)
            router?.openMail(with: supportData.emailDataCollector, recipient: supportData.recipient)
        } catch {
            alert = error.alertBinder
        }
    }
}
