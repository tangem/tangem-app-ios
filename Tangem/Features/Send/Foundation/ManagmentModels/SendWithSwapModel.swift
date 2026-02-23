//
//  SendWithSwapModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation

/// A composition model that combines `TransferModel` and `SwapModel`,
/// switching between them based on `_receivedToken` state.
/// This provides the same API as `SendModel` but with cleaner separation of concerns.
final class SendWithSwapModel {
    // MARK: - Data

    /// When nil: simple send mode (.same)
    /// When some: swap mode (.swap)
    private let _receivedToken: CurrentValueSubject<SendReceiveToken?, Never>

    // MARK: - Dependencies

    weak var router: SendWithSwapModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Models

    private let transferModel: TransferModel
    private let swapModel: SwapModel

    // MARK: - Private

    private let initialSourceToken: SendSourceToken
    private let sendAlertBuilder: SendAlertBuilder
    private let analyticsLogger: SendAnalyticsLogger
    private let transactionSigner: TangemSigner
    private var bag: Set<AnyCancellable> = []

    // MARK: - Public interface

    init(
        transferModel: TransferModel,
        swapModel: SwapModel,
        initialSourceToken: SendSourceToken,
        transactionSigner: TangemSigner,
        sendAlertBuilder: SendAlertBuilder,
        analyticsLogger: SendAnalyticsLogger
    ) {
        self.transferModel = transferModel
        self.swapModel = swapModel
        self.initialSourceToken = initialSourceToken
        self.transactionSigner = transactionSigner
        self.sendAlertBuilder = sendAlertBuilder
        self.analyticsLogger = analyticsLogger

        _receivedToken = .init(nil) // Start in simple send mode

        bind()
    }

    deinit {
        AppLogger.debug("SendWithSwapModel deinit")
    }
}

// MARK: - Binding

private extension SendWithSwapModel {
    func bind() {
        // Routers and alert presenters will be set externally
        // No adapters needed - direct delegation
    }
}

// MARK: - Reset flow

private extension SendWithSwapModel {
    func resetFlow(
        newReceiveToken: SendReceiveToken?,
        reset: @escaping () -> Void,
        cancel: @escaping () -> Void = {}
    ) {
        func resetFlowAction() {
            reset()
            transferModel.externalDestinationUpdater.externalUpdate(address: .init(value: .plain(""), source: .textField))
            router?.resetFlow()
        }

        // Check if both tokens have the same network
        let currentBlockchain = _receivedToken.value?.tokenItem.blockchain ?? initialSourceToken.tokenItem.blockchain
        let newBlockchain = newReceiveToken?.tokenItem.blockchain ?? initialSourceToken.tokenItem.blockchain

        if currentBlockchain == newBlockchain {
            // Same network, safe to switch
            reset()
            return
        }

        // Different networks, show confirmation
        switch newReceiveToken {
        case .some:
            // Switching to swap mode
            alertPresenter?.showAlert(
                sendAlertBuilder.makeChangeTokenFlowAlert(action: resetFlowAction, cancel: cancel)
            )
        case .none:
            // Switching back to simple send
            alertPresenter?.showAlert(
                sendAlertBuilder.makeCancelConvertingFlowAlert(action: resetFlowAction, cancel: cancel)
            )
        }
    }
}

// MARK: - SendDestinationInput

extension SendWithSwapModel: SendDestinationInput {
    var destination: SendDestination? {
        transferModel.destination
    }

    var destinationAdditionalField: SendDestinationAdditionalField {
        transferModel.destinationAdditionalField
    }

    var destinationPublisher: AnyPublisher<SendDestination?, Never> {
        transferModel.destinationPublisher
    }

    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> {
        transferModel.additionalFieldPublisher
    }
}

// MARK: - SendDestinationOutput

extension SendWithSwapModel: SendDestinationOutput {
    func destinationDidChanged(_ address: SendDestination?) {
        transferModel.destinationDidChanged(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField) {
        transferModel.destinationAdditionalParametersDidChanged(type)
    }
}

// MARK: - SendSourceTokenInput

extension SendWithSwapModel: SendSourceTokenInput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> {
        switch _receivedToken.value {
        case .none: transferModel.sourceToken
        case .some: swapModel.sourceToken
        }
    }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.sourceTokenPublisher
                case .some: model.swapModel.sourceTokenPublisher
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenOutput

extension SendWithSwapModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {
        switch _receivedToken.value {
        case .none: transferModel.userDidSelect(sourceToken: sourceToken)
        case .some: swapModel.userDidSelect(sourceToken: sourceToken)
        }
    }
}

// MARK: - SendSourceTokenAmountInput

extension SendWithSwapModel: SendSourceTokenAmountInput {
    var sourceAmount: LoadingResult<SendAmount, any Error> {
        switch _receivedToken.value {
        case .none: transferModel.sourceAmount
        case .some: swapModel.sourceAmount
        }
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.sourceAmountPublisher
                case .some: model.swapModel.sourceAmountPublisher
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenAmountOutput

extension SendWithSwapModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        switch _receivedToken.value {
        case .none: transferModel.sourceAmountDidChanged(amount: amount)
        case .some: swapModel.sourceAmountDidChanged(amount: amount)
        }
    }
}

// MARK: - SendReceiveTokenInput

extension SendWithSwapModel: SendReceiveTokenInput {
    var isReceiveTokenSelectionAvailable: Bool {
        swapModel.isReceiveTokenSelectionAvailable
    }

    var receiveToken: LoadingResult<any SendReceiveToken, any Error> {
        switch _receivedToken.value {
        case .none: .loading
        case .some: swapModel.receiveToken
        }
    }

    var receiveTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: Just(.loading as LoadingResult<any SendReceiveToken, any Error>).eraseToAnyPublisher()
                case .some: model.swapModel.receiveTokenPublisher
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenOutput

extension SendWithSwapModel: SendReceiveTokenOutput {
    func userDidRequestClearSelection() {
        resetFlow(newReceiveToken: nil, reset: { [weak self] in
            self?._receivedToken.send(nil)
            self?.analyticsLogger.logAmountStepOpened()
        })
    }

    func userDidRequestSelect(receiveToken: SendReceiveToken, selected: @escaping (Bool) -> Void) {
        resetFlow(newReceiveToken: receiveToken, reset: { [weak self] in
            self?._receivedToken.send(receiveToken)
            self?.swapModel.userDidRequestSelect(receiveToken: receiveToken, selected: selected)
            self?.analyticsLogger.logAmountStepOpened()
        }, cancel: { [weak self] in
            selected(false)
            self?.analyticsLogger.logAmountStepOpened()
        })
    }
}

// MARK: - SendReceiveTokenAmountInput

extension SendWithSwapModel: SendReceiveTokenAmountInput {
    var receiveAmount: LoadingResult<SendAmount, any Error> {
        switch _receivedToken.value {
        case .none: .failure(SendAmountError.noAmount)
        case .some: swapModel.receiveAmount
        }
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: Just(.failure(SendAmountError.noAmount) as LoadingResult<SendAmount, any Error>).eraseToAnyPublisher()
                case .some: model.swapModel.receiveAmountPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token -> AnyPublisher<HighPriceImpactCalculator.Result?, Never> in
                switch token {
                case .none: .just(output: .none)
                case .some: model.swapModel.highPriceImpactPublisher
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenAmountOutput

extension SendWithSwapModel: SendReceiveTokenAmountOutput {
    func receiveAmountDidChanged(amount: SendAmount?) {
        switch _receivedToken.value {
        case .none: break // Not supported for simple sends
        case .some: swapModel.receiveAmountDidChanged(amount: amount)
        }
    }
}

// MARK: - SendSwapProvidersInput

extension SendWithSwapModel: SendSwapProvidersInput {
    var expressProviders: [ExpressAvailableProvider] {
        get async {
            switch _receivedToken.value {
            case .none: []
            case .some: swapModel.expressProviders
            }
        }
    }

    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: Just([ExpressAvailableProvider]()).eraseToAnyPublisher()
                case .some: model.swapModel.expressProvidersPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? {
        switch _receivedToken.value {
        case .none: nil
        case .some: swapModel.selectedExpressProvider
        }
    }

    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: Just(nil as LoadingResult<ExpressAvailableProvider, any Error>?).eraseToAnyPublisher()
                case .some: model.swapModel.selectedExpressProviderPublisher
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSwapProvidersOutput

extension SendWithSwapModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        switch _receivedToken.value {
        case .none: break // Not supported
        case .some: swapModel.userDidSelect(provider: provider)
        }
    }
}

// MARK: - SendFeeUpdater

extension SendWithSwapModel: SendFeeUpdater {
    func updateFees() {
        switch _receivedToken.value {
        case .none: transferModel.updateFees()
        case .some: swapModel.userDidDismissFeeSelection()
        }
    }
}

// MARK: - SendFeeInput

extension SendWithSwapModel: SendFeeInput {
    var selectedFee: TokenFee? {
        switch _receivedToken.value {
        case .none: transferModel.selectedFee
        case .some: swapModel.selectedFee
        }
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.selectedFeePublisher
                case .some: model.swapModel.selectedFeePublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.supportFeeSelectionPublisher
                case .some: model.swapModel.supportFeeSelectionPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.shouldShowFeeSelectorRow
                case .some: model.swapModel.shouldShowFeeSelectorRow
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension SendWithSwapModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.isReadyToSendPublisher
                case .some: model.swapModel.isReadyToSendPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.isNotificationButtonIsLoading
                case .some: model.swapModel.isNotificationButtonIsLoading
                }
            }
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.summaryTransactionDataPublisher
                case .some: model.swapModel.summaryTransactionDataPublisher
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFinishInput

extension SendWithSwapModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        Publishers.Merge(
            transferModel.transactionSentDate,
            swapModel.transactionSentDate
        )
        .eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> {
        Publishers.Merge(
            transferModel.transactionURL,
            swapModel.transactionURL
        )
        .eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension SendWithSwapModel: SendBaseInput, SendBaseOutput {
    func stopSwapProvidersAutoUpdateTimer() {
        switch _receivedToken.value {
        case .none: transferModel.stopSwapProvidersAutoUpdateTimer()
        case .some: break // SwapModel handles this internally via autoupdatingTimer
        }
    }

    var actionInProcessing: AnyPublisher<Bool, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.actionInProcessing
                case .some: model.swapModel.actionInProcessing
                }
            }
            .eraseToAnyPublisher()
    }

    func actualizeInformation() {
        switch _receivedToken.value {
        case .none: transferModel.actualizeInformation()
        case .some: break // SwapModel handles this differently
        }
    }

    func performAction() async throws -> TransactionDispatcherResult {
        switch _receivedToken.value {
        case .none:
            // Simple send mode
            return try await transferModel.performAction()

        case .some:
            // Swap mode - check high price impact
            let highPriceImpactResult = try? await swapModel.highPriceImpactPublisher.first().async()

            if let highPriceImpact = highPriceImpactResult, highPriceImpact.isHighPriceImpact {
                let viewModel = HighPriceImpactWarningSheetViewModel(
                    highPriceImpact: highPriceImpact,
                    tangemIconProvider: CommonTangemIconProvider(signer: transactionSigner)
                )
                router?.openHighPriceImpactWarningSheetViewModel(viewModel: viewModel)

                return try await viewModel.process(send: { try await self.swapModel.performAction() })
            }

            return try await swapModel.performAction()
        }
    }
}

// MARK: - SendNotificationManagerInput

extension SendWithSwapModel: SendNotificationManagerInput {
    var feeValues: AnyPublisher<[TokenFee], Never> {
        switch _receivedToken.value {
        case .none: transferModel.feeValues
        case .some: Just([]).eraseToAnyPublisher() // SwapModel doesn't expose this
        }
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.selectedTokenFeePublisher
                case .some: model.swapModel.selectedFeePublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.isFeeIncludedPublisher
                case .some: Just(false).eraseToAnyPublisher() // Swap never includes fee
                }
            }
            .eraseToAnyPublisher()
    }

    var bsdkTransactionPublisher: AnyPublisher<BSDKTransaction?, Never> {
        switch _receivedToken.value {
        case .none: transferModel.bsdkTransactionPublisher
        case .some: Just(nil).eraseToAnyPublisher() // SwapModel doesn't expose this
        }
    }

    var transactionCreationError: AnyPublisher<Error?, Never> {
        switch _receivedToken.value {
        case .none: transferModel.transactionCreationError
        case .some: Just(nil).eraseToAnyPublisher() // SwapModel doesn't expose this
        }
    }
}

// MARK: - NotificationTapDelegate

extension SendWithSwapModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch _receivedToken.value {
        case .none: transferModel.didTapNotification(with: id, action: action)
        case .some: swapModel.didTapNotification(with: id, action: action)
        }
    }
}

// MARK: - SendBaseDataBuilderInput

extension SendWithSwapModel: SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? {
        switch _receivedToken.value {
        case .none: transferModel.bsdkAmount
        case .some: swapModel.bsdkAmount
        }
    }

    var bsdkFee: BSDKFee? {
        switch _receivedToken.value {
        case .none: transferModel.bsdkFee
        case .some: swapModel.bsdkFee
        }
    }

    var isFeeIncluded: Bool {
        switch _receivedToken.value {
        case .none: transferModel.isFeeIncluded
        case .some: swapModel.isFeeIncluded
        }
    }
}

// MARK: - SendApproveDataBuilderInput

extension SendWithSwapModel: SendApproveDataBuilderInput {
    var approveRequestedByExpressProvider: ExpressProvider? {
        switch _receivedToken.value {
        case .none: nil
        case .some: swapModel.approveRequestedByExpressProvider
        }
    }

    var approveViewModelInput: (any ApproveViewModelInput)? {
        switch _receivedToken.value {
        case .none: nil
        case .some: swapModel.approveViewModelInput
        }
    }

    var approveRequestedWithSelectedPolicy: ApprovePolicy? {
        switch _receivedToken.value {
        case .none: nil
        case .some: swapModel.approveRequestedWithSelectedPolicy
        }
    }
}

// MARK: - SendDestinationAccountOutput

extension SendWithSwapModel: SendDestinationAccountOutput {
    func setDestinationAccountInfo(
        tokenHeader: ExpressInteractorTokenHeader?,
        analyticsProvider: (any AccountModelAnalyticsProviding)?
    ) {
        transferModel.setDestinationAccountInfo(tokenHeader: tokenHeader, analyticsProvider: analyticsProvider)
    }
}

// MARK: - TokenFeeProvidersManagerProviding

extension SendWithSwapModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: TokenFeeProvidersManager? {
        switch _receivedToken.value {
        case .none: transferModel.tokenFeeProvidersManager
        case .some: swapModel.tokenFeeProvidersManager
        }
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<TokenFeeProvidersManager, Never> {
        _receivedToken
            .withWeakCaptureOf(self)
            .flatMapLatest { model, token in
                switch token {
                case .none: model.transferModel.tokenFeeProvidersManagerPublisher
                case .some: model.swapModel.tokenFeeProvidersManagerPublisher
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorOutput

extension SendWithSwapModel: FeeSelectorOutput {
    func userDidDismissFeeSelection() {
        switch _receivedToken.value {
        case .none: transferModel.userDidDismissFeeSelection()
        case .some: swapModel.userDidDismissFeeSelection()
        }
    }

    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        switch _receivedToken.value {
        case .none: transferModel.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption)
        case .some: swapModel.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption)
        }
    }
}
