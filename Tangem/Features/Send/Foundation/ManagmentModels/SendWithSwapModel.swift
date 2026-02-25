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
/// switching between them based on SwapModel's receive token state.
/// When the receive token has a value, swap mode is active.
/// Otherwise, it operates in simple send mode using TransferModel.
/// This provides the same API as `SendModel` but with cleaner separation of concerns.
final class SendWithSwapModel {
    // MARK: - Dependencies

    var externalDestinationUpdater: SendDestinationExternalUpdater!

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
    }

    deinit {
        AppLogger.debug("SendWithSwapModel deinit")
    }
}

// MARK: - Binding

private extension SendWithSwapModel {
    /// Determines if we're in swap mode based on SwapModel's receive token
    /// Returns true if swap mode is active (receive token exists)
    var isSwapMode: Bool {
        switch swapModel.receiveToken {
        case .success: true
        case .loading, .failure: false
        }
    }

    /// Publisher that emits true when in swap mode, false when in simple send mode
    var isSwapModePublisher: AnyPublisher<Bool, Never> {
        swapModel.receiveTokenPublisher
            .map { $0.value != nil }
            .eraseToAnyPublisher()
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
        let currentReceiveToken = swapModel.receiveToken.value
        let currentBlockchain = currentReceiveToken?.tokenItem.blockchain ?? initialSourceToken.tokenItem.blockchain
        let newBlockchain = newReceiveToken?.tokenItem.blockchain ?? initialSourceToken.tokenItem.blockchain
        let isSameNetwork = currentBlockchain == newBlockchain

        // Different networks, show confirmation
        switch newReceiveToken {
        // If we don't have any destination address
        // We can safely change the token
        case _ where destination == nil:
            reset()

        // Same network, safe to switch
        case _ where isSameNetwork:
            reset()

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
        isSwapMode ? swapModel.sourceToken : transferModel.sourceToken
    }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.sourceTokenPublisher : model.transferModel.sourceTokenPublisher
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenOutput

extension SendWithSwapModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {
        swapModel.userDidSelect(sourceToken: sourceToken)
        transferModel.userDidSelect(sourceToken: sourceToken)
    }
}

// MARK: - SendSourceTokenAmountInput

extension SendWithSwapModel: SendSourceTokenAmountInput {
    var sourceAmount: LoadingResult<SendAmount, any Error> {
        isSwapMode ? swapModel.sourceAmount : transferModel.sourceAmount
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.sourceAmountPublisher : model.transferModel.sourceAmountPublisher
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenAmountOutput

extension SendWithSwapModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        swapModel.sourceAmountDidChanged(amount: amount)
        transferModel.sourceAmountDidChanged(amount: amount)
    }
}

// MARK: - SendReceiveTokenInput

extension SendWithSwapModel: SendReceiveTokenInput {
    var isReceiveTokenSelectionAvailable: Bool {
        swapModel.isReceiveTokenSelectionAvailable
    }

    var receiveToken: LoadingResult<any SendReceiveToken, any Error> {
        isSwapMode ? swapModel.receiveToken : .loading
    }

    var receiveTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.receiveTokenPublisher : .just(output: .loading)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenOutput

extension SendWithSwapModel: SendReceiveTokenOutput {
    func userDidRequestClearSelection() {
        // When clearing, we need to reset the swap model back to the initial source token
        // This effectively switches back to "simple send" mode
        resetFlow(newReceiveToken: .none, reset: { [weak self] in
            self?.swapModel.userDidRequestClearSelection()
            self?.analyticsLogger.logAmountStepOpened()
        })
    }

    func userDidRequestSelect(receiveToken: SendReceiveToken, selected: @escaping (Bool) -> Void) {
        resetFlow(newReceiveToken: receiveToken, reset: { [weak self] in
            self?.swapModel.userDidRequestSelect(receiveToken: receiveToken, selected: selected)
            self?.analyticsLogger.logAmountStepOpened()
            selected(true)
        }, cancel: { [weak self] in
            self?.analyticsLogger.logAmountStepOpened()
            selected(false)
        })
    }
}

// MARK: - SendReceiveTokenAmountInput

extension SendWithSwapModel: SendReceiveTokenAmountInput {
    var receiveAmount: LoadingResult<SendAmount, any Error> {
        isSwapMode ? swapModel.receiveAmount : .failure(SendAmountError.noAmount)
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.receiveAmountPublisher : .just(output: .failure(SendAmountError.noAmount))
            }
            .eraseToAnyPublisher()
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap -> AnyPublisher<HighPriceImpactCalculator.Result?, Never> in
                isSwap ? model.swapModel.highPriceImpactPublisher : .just(output: .none)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenAmountOutput

extension SendWithSwapModel: SendReceiveTokenAmountOutput {
    func receiveAmountDidChanged(amount: SendAmount?) {
        swapModel.receiveAmountDidChanged(amount: amount)
    }
}

// MARK: - SendSwapProvidersInput

extension SendWithSwapModel: SendSwapProvidersInput {
    var expressProviders: [ExpressAvailableProvider] {
        get async {
            isSwapMode ? swapModel.expressProviders : []
        }
    }

    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.expressProvidersPublisher : .just(output: [])
            }
            .eraseToAnyPublisher()
    }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? {
        isSwapMode ? swapModel.selectedExpressProvider : nil
    }

    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.selectedExpressProviderPublisher : .just(output: nil)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSwapProvidersOutput

extension SendWithSwapModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        swapModel.userDidSelect(provider: provider)
    }
}

// MARK: - SendFeeUpdater

extension SendWithSwapModel: SendFeeUpdater {
    func updateFees() {
        if isSwapMode {
            swapModel.updateFees()
        } else {
            transferModel.updateFees()
        }
    }
}

// MARK: - SendFeeInput

extension SendWithSwapModel: SendFeeInput {
    var selectedFee: TokenFee? {
        isSwapMode ? swapModel.selectedFee : transferModel.selectedFee
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.selectedFeePublisher : model.transferModel.selectedFeePublisher
            }
            .eraseToAnyPublisher()
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.supportFeeSelectionPublisher : model.transferModel.supportFeeSelectionPublisher
            }
            .eraseToAnyPublisher()
    }

    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.shouldShowFeeSelectorRow : model.transferModel.shouldShowFeeSelectorRow
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension SendWithSwapModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.isReadyToSendPublisher : model.transferModel.isReadyToSendPublisher
            }
            .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.isNotificationButtonIsLoading : model.transferModel.isNotificationButtonIsLoading
            }
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.summaryTransactionDataPublisher : model.transferModel.summaryTransactionDataPublisher
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
        if !isSwapMode {
            transferModel.stopSwapProvidersAutoUpdateTimer()
        }
        // SwapModel handles this internally via autoupdatingTimer
    }

    var actionInProcessing: AnyPublisher<Bool, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.actionInProcessing : model.transferModel.actionInProcessing
            }
            .eraseToAnyPublisher()
    }

    func actualizeInformation() {
        if !isSwapMode {
            transferModel.actualizeInformation()
        }
        // SwapModel handles this differently
    }

    func performAction() async throws -> TransactionDispatcherResult {
        if isSwapMode {
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
        } else {
            // Simple send mode
            return try await transferModel.performAction()
        }
    }
}

// MARK: - SendNotificationManagerInput

extension SendWithSwapModel: SendNotificationManagerInput {
    var feeValues: AnyPublisher<[TokenFee], Never> {
        isSwapMode ? Just([]).eraseToAnyPublisher() : transferModel.feeValues
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.selectedFeePublisher : model.transferModel.selectedTokenFeePublisher
            }
            .eraseToAnyPublisher()
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? Just(false).eraseToAnyPublisher() : model.transferModel.isFeeIncludedPublisher
            }
            .eraseToAnyPublisher()
    }

    var bsdkTransactionPublisher: AnyPublisher<BSDKTransaction?, Never> {
        isSwapMode ? Just(nil).eraseToAnyPublisher() : transferModel.bsdkTransactionPublisher
    }

    var transactionCreationError: AnyPublisher<Error?, Never> {
        isSwapMode ? Just(nil).eraseToAnyPublisher() : transferModel.transactionCreationError
    }
}

// MARK: - NotificationTapDelegate

extension SendWithSwapModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        if isSwapMode {
            swapModel.didTapNotification(with: id, action: action)
        } else {
            transferModel.didTapNotification(with: id, action: action)
        }
    }
}

// MARK: - SendBaseDataBuilderInput

extension SendWithSwapModel: SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? {
        isSwapMode ? swapModel.bsdkAmount : transferModel.bsdkAmount
    }

    var bsdkFee: BSDKFee? {
        isSwapMode ? swapModel.bsdkFee : transferModel.bsdkFee
    }

    var isFeeIncluded: Bool {
        isSwapMode ? swapModel.isFeeIncluded : transferModel.isFeeIncluded
    }
}

// MARK: - SendApproveDataBuilderInput

extension SendWithSwapModel: SendApproveDataBuilderInput {
    var approveRequestedByExpressProvider: ExpressProvider? {
        isSwapMode ? swapModel.approveRequestedByExpressProvider : nil
    }

    var approveViewModelInput: (any ApproveViewModelInput)? {
        isSwapMode ? swapModel.approveViewModelInput : nil
    }

    var approveRequestedWithSelectedPolicy: ApprovePolicy? {
        isSwapMode ? swapModel.approveRequestedWithSelectedPolicy : nil
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
        isSwapMode ? swapModel.tokenFeeProvidersManager : transferModel.tokenFeeProvidersManager
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<TokenFeeProvidersManager, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? model.swapModel.tokenFeeProvidersManagerPublisher : model.transferModel.tokenFeeProvidersManagerPublisher
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorOutput

extension SendWithSwapModel: FeeSelectorOutput {
    func userDidDismissFeeSelection() {
        if isSwapMode {
            swapModel.userDidDismissFeeSelection()
        } else {
            transferModel.userDidDismissFeeSelection()
        }
    }

    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        if isSwapMode {
            swapModel.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption)
        } else {
            transferModel.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption)
        }
    }
}
