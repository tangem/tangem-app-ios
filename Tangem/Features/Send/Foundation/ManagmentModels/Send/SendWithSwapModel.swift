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
/// This provides clean separation of concerns between send and swap functionality.
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
    private var receiveTokenUpdatingTask: Task<Void, Error>?

    init(
        transferModel: TransferModel,
        swapModel: SwapModel,
        initialSourceToken: SendSourceToken,
        sendAlertBuilder: SendAlertBuilder,
        analyticsLogger: SendAnalyticsLogger
    ) {
        self.transferModel = transferModel
        self.swapModel = swapModel
        self.initialSourceToken = initialSourceToken
        self.sendAlertBuilder = sendAlertBuilder
        self.analyticsLogger = analyticsLogger
    }

    deinit {
        AppLogger.debug("SendWithSwapModel deinit")
    }
}

// MARK: - Mode Switching

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

    /// Returns value from swap or transfer model based on current mode.
    func modeSwitch<T>(swap: @autoclosure () -> T, transfer: @autoclosure () -> T) -> T {
        isSwapMode ? swap() : transfer()
    }

    /// Creates a publisher that switches between swap and transfer model publishers
    /// based on the current mode. Replaces the repeated 6-line `isSwapModePublisher.flatMapLatest` pattern.
    func modeSwitchedPublisher<T>(
        swap: @escaping (SwapModel) -> AnyPublisher<T, Never>,
        transfer: @escaping (TransferModel) -> AnyPublisher<T, Never>
    ) -> AnyPublisher<T, Never> {
        isSwapModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isSwap in
                isSwap ? swap(model.swapModel) : transfer(model.transferModel)
            }
            .eraseToAnyPublisher()
    }

    /// Delegates a method call to swap or transfer model based on current mode.
    func modeDelegated(swap: (SwapModel) -> Void, transfer: (TransferModel) -> Void) {
        if isSwapMode {
            swap(swapModel)
        } else {
            transfer(transferModel)
        }
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

            if let tokenItem = newReceiveToken?.tokenItem {
                externalDestinationUpdater.externalUpdate(additionalField: .field(for: tokenItem.blockchain))
            } else {
                externalDestinationUpdater.externalUpdate(additionalField: .notSupported)
            }
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

    func updateReceiveTokenIfNeededWithDebounce() {
        receiveTokenUpdatingTask?.cancel()
        receiveTokenUpdatingTask = Task { @MainActor [weak self] in
            // Use small debounce to avoid recreating providers.
            try await Task.sleep(for: .seconds(1))
            try Task.checkCancellation()
            self?.updateReceiveTokenIfNeeded()
        }
    }

    func updateReceiveTokenIfNeeded() {
        guard let receiveTokenItem = swapModel.receiveToken.value else {
            return
        }

        let newDestination = transferModel.destination?.value.transactionAddress
        let newExtraId = transferModel.destinationAdditionalField.extraId

        guard newDestination != receiveTokenItem.address || newExtraId != receiveTokenItem.extraId else {
            // Already set all
            return
        }

        let destination = transferModel.destination.map { destination in
            SendReceiveTokenDestination(
                destination: destination.value,
                destinationTag: transferModel.destinationAdditionalField.extraId
            )
        }

        let receiveToken = CommonSendReceiveTokenFactory(tokenItem: receiveTokenItem.tokenItem)
            .makeSendReceiveToken(destination: destination)

        swapModel.update(receive: receiveToken)
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
        updateReceiveTokenIfNeededWithDebounce()
    }

    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField) {
        transferModel.destinationAdditionalParametersDidChanged(type)
        updateReceiveTokenIfNeededWithDebounce()
    }
}

// MARK: - SendSourceTokenInput

extension SendWithSwapModel: SendSourceTokenInput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> {
        modeSwitch(swap: swapModel.sourceToken, transfer: transferModel.sourceToken)
    }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        modeSwitchedPublisher(swap: \.sourceTokenPublisher, transfer: \.sourceTokenPublisher)
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
        modeSwitch(swap: swapModel.sourceAmount, transfer: transferModel.sourceAmount)
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        modeSwitchedPublisher(swap: \.sourceAmountPublisher, transfer: \.sourceAmountPublisher)
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
        modeSwitch(swap: swapModel.receiveToken, transfer: .loading)
    }

    var receiveTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        modeSwitchedPublisher(
            swap: { $0.receiveTokenPublisher },
            transfer: { _ in .just(output: .loading) }
        )
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

    func userDidRequestSelect(receiveTokenItem: TokenItem, selected: @escaping (Bool) -> Void) {
        let destination = transferModel.destination.map { destination in
            SendReceiveTokenDestination(
                destination: destination.value,
                destinationTag: transferModel.destinationAdditionalField.extraId
            )
        }

        let receiveToken = CommonSendReceiveTokenFactory(tokenItem: receiveTokenItem)
            .makeSendReceiveToken(destination: destination)

        resetFlow(newReceiveToken: receiveToken, reset: { [weak self] in
            self?.swapModel.update(receive: receiveToken)
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
        modeSwitch(swap: swapModel.receiveAmount, transfer: .failure(SendAmountError.noAmount))
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        modeSwitchedPublisher(
            swap: { $0.receiveAmountPublisher },
            transfer: { _ in .just(output: .failure(SendAmountError.noAmount)) }
        )
    }

    var exchangeRestrictionPublisher: AnyPublisher<ExchangeAmountRestriction?, Never> {
        modeSwitchedPublisher(
            swap: { $0.exchangeRestrictionPublisher },
            transfer: { _ in .just(output: nil) }
        )
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        modeSwitchedPublisher(
            swap: { $0.highPriceImpactPublisher },
            transfer: { _ in .just(output: .none) }
        )
    }
}

// MARK: - SendReceiveTokenAmountOutput

extension SendWithSwapModel: SendReceiveTokenAmountOutput {
    func receiveAmountDidChange(amount: SendAmount?) {
        swapModel.receiveAmountDidChange(amount: amount)
    }
}

// MARK: - SendSwapProvidersInput

extension SendWithSwapModel: SendSwapProvidersInput {
    var expressProviders: [ExpressAvailableProvider] {
        modeSwitch(swap: swapModel.expressProviders, transfer: [])
    }

    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        modeSwitchedPublisher(
            swap: { $0.expressProvidersPublisher },
            transfer: { _ in .just(output: []) }
        )
    }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? {
        modeSwitch(swap: swapModel.selectedExpressProvider, transfer: nil)
    }

    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> {
        modeSwitchedPublisher(
            swap: { $0.selectedExpressProviderPublisher },
            transfer: { _ in .just(output: nil) }
        )
    }

    var currentRateType: ExpressProviderRateType? {
        modeSwitch(swap: swapModel.currentRateType, transfer: nil)
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
        modeDelegated(swap: { $0.updateFees() }, transfer: { $0.updateFees() })
    }
}

// MARK: - SendFeeInput

extension SendWithSwapModel: SendFeeInput {
    var selectedFee: TokenFee? {
        modeSwitch(swap: swapModel.selectedFee, transfer: transferModel.selectedFee)
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        modeSwitchedPublisher(swap: \.selectedFeePublisher, transfer: \.selectedFeePublisher)
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        modeSwitchedPublisher(swap: \.supportFeeSelectionPublisher, transfer: \.supportFeeSelectionPublisher)
    }

    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> {
        modeSwitchedPublisher(swap: \.shouldShowFeeSelectorRow, transfer: \.shouldShowFeeSelectorRow)
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension SendWithSwapModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        modeSwitchedPublisher(swap: \.isReadyToSendPublisher, transfer: \.isReadyToSendPublisher)
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        modeSwitchedPublisher(swap: \.isNotificationButtonIsLoading, transfer: \.isNotificationButtonIsLoading)
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        modeSwitchedPublisher(swap: \.summaryTransactionDataPublisher, transfer: \.summaryTransactionDataPublisher)
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
        modeSwitchedPublisher(swap: \.actionInProcessing, transfer: \.actionInProcessing)
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
            let highPriceImpactResult = try await swapModel.highPriceImpactPublisher.first().async()
            let source = try swapModel.sourceToken.get()

            if let highPriceImpact = highPriceImpactResult, !highPriceImpact.level.isNegligible {
                let viewModel = HighPriceImpactWarningSheetViewModel(
                    highPriceImpact: highPriceImpact,
                    tangemIconProvider: CommonTangemIconProvider(signer: source.userWalletInfo.signer)
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
        modeSwitchedPublisher(
            swap: { _ in .just(output: []) },
            transfer: { $0.feeValues }
        )
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        modeSwitchedPublisher(
            swap: { $0.selectedFeePublisher },
            transfer: { $0.selectedTokenFeePublisher }
        )
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        modeSwitchedPublisher(
            swap: { _ in .just(output: false) },
            transfer: { $0.isFeeIncludedPublisher }
        )
    }

    var bsdkTransactionResultPublisher: AnyPublisher<Result<BSDKTransaction, Error>?, Never> {
        modeSwitchedPublisher(
            swap: { _ in .just(output: nil) },
            transfer: { $0.bsdkTransactionResultPublisher }
        )
    }
}

// MARK: - NotificationTapDelegate

extension SendWithSwapModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        modeDelegated(
            swap: { $0.didTapNotification(with: id, action: action) },
            transfer: { $0.didTapNotification(with: id, action: action) }
        )
    }
}

// MARK: - SendBaseDataBuilderInput

extension SendWithSwapModel: SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? {
        modeSwitch(swap: swapModel.bsdkAmount, transfer: transferModel.bsdkAmount)
    }

    var bsdkFee: BSDKFee? {
        modeSwitch(swap: swapModel.bsdkFee, transfer: transferModel.bsdkFee)
    }

    var isFeeIncluded: Bool {
        modeSwitch(swap: swapModel.isFeeIncluded, transfer: transferModel.isFeeIncluded)
    }
}

// MARK: - ApproveFlowDataProvider, ApproveOutput

extension SendWithSwapModel: ApproveFlowDataProvider, ApproveOutput {
    func approveFlowInput() throws -> ApproveFlowInput {
        guard isSwapMode else {
            throw SendApproveViewModelInputDataBuilderError.notSupported
        }

        return try swapModel.approveFlowInput()
    }

    func approveDidSendTransaction() {
        guard isSwapMode else { return }
        swapModel.approveDidSendTransaction()
    }
}

// MARK: - SendDestinationAccountOutput

extension SendWithSwapModel: SendDestinationAccountOutput {
    func setDestinationAccountInfo(
        analyticsProvider: (any AccountModelAnalyticsProviding)?
    ) {
        transferModel.setDestinationAccountInfo(analyticsProvider: analyticsProvider)
    }
}

// MARK: - TokenFeeProvidersManagerProviding

extension SendWithSwapModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: TokenFeeProvidersManager? {
        modeSwitch(swap: swapModel.tokenFeeProvidersManager, transfer: transferModel.tokenFeeProvidersManager)
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<TokenFeeProvidersManager, Never> {
        modeSwitchedPublisher(swap: \.tokenFeeProvidersManagerPublisher, transfer: \.tokenFeeProvidersManagerPublisher)
    }
}

// MARK: - FeeSelectorOutput

extension SendWithSwapModel: FeeSelectorOutput {
    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        modeDelegated(
            swap: { $0.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption) },
            transfer: { $0.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption) }
        )
    }
}
