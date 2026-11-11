//
//  LendingDepositConfirmViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import BlockchainSdk
import TangemFoundation
import TangemLocalization
import struct TangemUIUtils.AlertBinder

@MainActor
final class LendingDepositConfirmViewModel: ObservableObject {
    typealias StateModel = LendingDepositConfirmContentView.StateModel
    typealias Action = LendingDepositConfirmContentView.Action

    @Published private(set) var state: StateModel
    @Published var alert: AlertBinder?

    private(set) var depositTask: Task<Void, Never>?

    private let transferModel: TransferModel
    private let sourceToken: SendTransferableToken
    private let projection: LendingDepositProjection
    private let mailDataBuilder: SendMailDataBuilder
    // [REDACTED_TODO_COMMENT]
    private let alertBuilder = LendingFailureAlertBuilder(failureMessage: "Something went wrong with your deposit. Please try again later.")
    private weak var coordinator: LendingDepositConfirmRoutable?
    private var bag: Set<AnyCancellable> = []

    init(
        transferModel: TransferModel,
        sourceToken: SendTransferableToken,
        projection: LendingDepositProjection,
        mailDataBuilder: SendMailDataBuilder,
        coordinator: LendingDepositConfirmRoutable?
    ) {
        self.transferModel = transferModel
        self.sourceToken = sourceToken
        self.projection = projection
        self.mailDataBuilder = mailDataBuilder
        self.coordinator = coordinator

        state = StateModel(
            tokenIconInfo: TokenIconInfoBuilder().build(from: sourceToken.tokenItem, isCustom: sourceToken.isCustom),
            fiatAmount: BalanceFormatter.defaultEmptyBalanceString,
            cryptoAmount: BalanceFormatter.defaultEmptyBalanceString,
            currentApy: projection.currentApy,
            performanceFee: projection.performanceFee,
            projectedEarnings: BalanceFormatter.defaultEmptyBalanceString,
            fee: .loading,
            canChangeFeeSpeed: false,
            signingActionButtonType: sourceToken.signingActionButtonType,
            isDepositEnabled: false,
            isDepositing: false
        )

        bind()
    }

    func handle(_ action: Action) {
        switch action {
        case .close:
            coordinator?.closeDeposit()
        case .fee:
            coordinator?.openFeeSelector()
        case .retryFee:
            transferModel.updateFees(amountOrBalance: transferModel.sourceAmount.value?.crypto)
        case .openURL(let url):
            guard !state.isDepositing else { return }
            coordinator?.openURL(url)
        case .deposit:
            deposit()
        }
    }
}

// MARK: - Private

private extension LendingDepositConfirmViewModel {
    func bind() {
        transferModel.sourceAmountPublisher
            .map(\.value)
            .receiveOnMain()
            .sink { [weak self] amount in
                self?.amountDidChange(amount)
            }
            .store(in: &bag)

        transferModel.selectedFeePublisher
            .receiveOnMain()
            .sink { [weak self] tokenFee in
                self?.state.fee = LendingFee(tokenFee)
            }
            .store(in: &bag)

        transferModel.supportFeeSelectionPublisher
            .receiveOnMain()
            .sink { [weak self] canChangeFeeSpeed in
                self?.state.canChangeFeeSpeed = canChangeFeeSpeed
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            transferModel.isReadyToSendPublisher,
            transferModel.isFeeIncludedPublisher,
            transferModel.sourceAmountPublisher.map { ($0.value?.crypto ?? 0) > 0 }
        )
        .map { isReadyToSend, isFeeIncluded, hasAmount in isReadyToSend && !isFeeIncluded && hasAmount }
        .removeDuplicates()
        .receiveOnMain()
        .sink { [weak self] isDepositEnabled in
            self?.state.isDepositEnabled = isDepositEnabled
        }
        .store(in: &bag)

        transferModel.actionInProcessing
            .removeDuplicates()
            .receiveOnMain()
            .sink { [weak self] isDepositing in
                self?.state.isDepositing = isDepositing
            }
            .store(in: &bag)
    }

    func amountDidChange(_ amount: SendAmount?) {
        let tokenItem = sourceToken.tokenItem
        let cryptoFormatter = SendCryptoValueFormatter(decimals: tokenItem.decimalCount, currencySymbol: tokenItem.currencySymbol, trimFractions: true)

        state.cryptoAmount = amount?.crypto.flatMap(cryptoFormatter.string(from:)) ?? BalanceFormatter.defaultEmptyBalanceString
        state.fiatAmount = BalanceFormatter().formatFiatBalance(amount?.fiat)
        state.projectedEarnings = amount?.fiat.map(projection.yearlyEarnings(fiatAmount:)) ?? BalanceFormatter.defaultEmptyBalanceString
    }

    func deposit() {
        guard depositTask == nil else {
            return
        }

        depositTask = Task { @MainActor [weak self] in
            await self?.performDeposit()
            self?.depositTask = nil
        }
    }

    @MainActor
    func performDeposit() async {
        do {
            _ = try await transferModel.performAction()
            coordinator?.depositDidSend()
        } catch is CancellationError {
            return
        } catch let error as TransactionDispatcherResult.Error {
            alert = makeAlert(for: error)
        } catch {
            AppLogger.error(error: error)
            alert = error.alertBinder
        }
    }

    func makeAlert(for error: TransactionDispatcherResult.Error) -> AlertBinder? {
        alertBuilder.makeAlert(
            for: error,
            retryFee: { [weak self] in self?.transferModel.actualizeInformation() },
            openSupport: { [weak self] transaction, error in self?.openSupport(transaction: transaction, error: error) }
        )
    }

    func openSupport(transaction: TransactionDispatcherTransactionType, error: SendTxError) {
        guard case .transfer(let transaction) = transaction else {
            return
        }

        do {
            let supportData = try mailDataBuilder.makeSupportData(transaction: transaction, error: error)
            coordinator?.openMail(with: supportData.emailDataCollector, recipient: supportData.recipient)
        } catch {
            alert = error.alertBinder
        }
    }
}
