//
//  TransferWithSwapModel.swift
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

/// A composition model that combines `SwapModel` (primary) and `TransferModel` (secondary),
/// switching between them based on whether source and receive tokens are identical.
/// When the receive `tokenItem` equals the source `tokenItem`, transfer mode is active —
/// the screen behaves like a regular Send to another account; otherwise it operates in swap mode.
/// Mirror of `SendWithSwapModel`, but oriented around the Swap screen.
final class TransferWithSwapModel {
    // MARK: - Dependencies

    weak var router: SwapModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Models

    private let swapModel: SwapModel
    private let transferModel: TransferModel

    // MARK: - Private

    private let analyticsLogger: SendAnalyticsLogger
    private var bag: Set<AnyCancellable> = []

    init(
        swapModel: SwapModel,
        transferModel: TransferModel,
        analyticsLogger: SendAnalyticsLogger
    ) {
        self.swapModel = swapModel
        self.transferModel = transferModel
        self.analyticsLogger = analyticsLogger

        bind()
    }

    deinit {
        AppLogger.debug("TransferWithSwapModel deinit")
    }
}

// MARK: - TransferWithSwapModelInput

extension TransferWithSwapModel: TransferWithSwapModelInput {
    /// Determines if we're in transfer mode: receive token's `tokenItem` matches the source's.
    var isTransferMode: Bool {
        guard let source = swapModel.sourceToken.value?.tokenItem,
              let receive = swapModel.receiveToken.value?.tokenItem else {
            return false
        }
        return source == receive
    }

    /// Publisher emitting true when source and receive tokens are identical (transfer mode).
    var isTransferModePublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            swapModel.sourceTokenPublisher,
            swapModel.receiveTokenPublisher
        )
        .map { source, receive in
            guard let sourceItem = source.value?.tokenItem,
                  let receiveItem = receive.value?.tokenItem else {
                return false
            }
            return sourceItem == receiveItem
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}

// MARK: - Binding

private extension TransferWithSwapModel {
    func bind() {
        // Push the receive-token's destination address/tag into the TransferModel
        // whenever we enter transfer mode or the receive token changes.
        swapModel.receiveTokenPublisher
            .withWeakCaptureOf(self)
            .sink { model, receive in
                model.syncTransferDestinationIfNeeded(receiveToken: receive.value)
            }
            .store(in: &bag)
    }

    func syncTransferDestinationIfNeeded(receiveToken: (any SendReceiveToken)?) {
        guard isTransferMode, let receiveToken else { return }
        guard let destination = receiveToken.destination else { return }

        transferModel.externalDestinationUpdater?.externalUpdate(
            address: SendDestination(value: destination.destination, source: .myWallet)
        )

        let blockchain = receiveToken.tokenItem.blockchain
        let additionalField: SendDestinationAdditionalField = {
            guard let type = SendDestinationAdditionalFieldType.type(for: blockchain) else {
                return .notSupported
            }

            guard let tag = destination.destinationTag?.nilIfEmpty else {
                return .empty(type: type)
            }

            do {
                let params = try TransactionParamsBuilder(blockchain: blockchain).transactionParameters(value: tag)
                return .filled(type: type, value: tag, params: params)
            } catch {
                return .empty(type: type)
            }
        }()

        transferModel.externalDestinationUpdater?.externalUpdate(additionalField: additionalField)
    }
}

// MARK: - SendSourceTokenInput

extension TransferWithSwapModel: SendSourceTokenInput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> {
        swapModel.sourceToken
    }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        swapModel.sourceTokenPublisher
    }
}

// MARK: - SendSourceTokenOutput

extension TransferWithSwapModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {
        swapModel.userDidSelect(sourceToken: sourceToken)
        transferModel.userDidSelect(sourceToken: sourceToken)
    }
}

// MARK: - SendSourceTokenAmountInput

extension TransferWithSwapModel: SendSourceTokenAmountInput {
    var sourceAmount: LoadingResult<SendAmount, any Error> {
        isTransferMode ? transferModel.sourceAmount : swapModel.sourceAmount
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.sourceAmountPublisher : model.swapModel.sourceAmountPublisher
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenAmountOutput

extension TransferWithSwapModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        swapModel.sourceAmountDidChanged(amount: amount)
        transferModel.sourceAmountDidChanged(amount: amount)
    }
}

// MARK: - SendReceiveTokenInput

extension TransferWithSwapModel: SendReceiveTokenInput {
    var isReceiveTokenSelectionAvailable: Bool {
        swapModel.isReceiveTokenSelectionAvailable
    }

    var receiveToken: LoadingResult<any SendReceiveToken, any Error> {
        swapModel.receiveToken
    }

    var receiveTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        swapModel.receiveTokenPublisher
    }
}

// MARK: - SendReceiveTokenOutput

extension TransferWithSwapModel: SendReceiveTokenOutput {
    func userDidRequestClearSelection() {
        swapModel.userDidRequestClearSelection()
    }

    func userDidRequestSelect(receiveTokenItem: TokenItem, selected: @escaping (Bool) -> Void) {
        assertionFailure("userDidRequestSelect(receiveTokenItem:) is not supposed to be called for swap-style flow. Use SwapTokenSelectorOutput.")
        selected(false)
    }
}

// MARK: - SendReceiveTokenAmountInput

extension TransferWithSwapModel: SendReceiveTokenAmountInput {
    var receiveAmount: LoadingResult<SendAmount, any Error> {
        isTransferMode ? .failure(SendAmountError.noAmount) : swapModel.receiveAmount
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? .just(output: .failure(SendAmountError.noAmount)) : model.swapModel.receiveAmountPublisher
            }
            .eraseToAnyPublisher()
    }

    var exchangeRestrictionPublisher: AnyPublisher<ExchangeAmountRestriction?, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? .just(output: nil) : model.swapModel.exchangeRestrictionPublisher
            }
            .eraseToAnyPublisher()
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer -> AnyPublisher<HighPriceImpactCalculator.Result?, Never> in
                isTransfer ? .just(output: .none) : model.swapModel.highPriceImpactPublisher
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenAmountOutput

extension TransferWithSwapModel: SendReceiveTokenAmountOutput {
    func receiveAmountDidChange(amount: SendAmount?) {
        swapModel.receiveAmountDidChange(amount: amount)
    }
}

// MARK: - SendSwapProvidersInput

//
// Provider data is suppressed in transfer mode. SwapSummaryProviderViewModel renders nothing
// when `selectedExpressProvider` is nil — that hides the Provider panel naturally, without UI changes.

extension TransferWithSwapModel: SendSwapProvidersInput {
    var expressProviders: [ExpressAvailableProvider] {
        isTransferMode ? [] : swapModel.expressProviders
    }

    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? .just(output: []) : model.swapModel.expressProvidersPublisher
            }
            .eraseToAnyPublisher()
    }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? {
        isTransferMode ? nil : swapModel.selectedExpressProvider
    }

    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? .just(output: nil) : model.swapModel.selectedExpressProviderPublisher
            }
            .eraseToAnyPublisher()
    }

    var currentRateType: ExpressProviderRateType? {
        isTransferMode ? nil : swapModel.currentRateType
    }

    var currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? .just(output: nil) : model.swapModel.currentRateTypePublisher
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendSwapProvidersOutput

extension TransferWithSwapModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        guard !isTransferMode else { return }
        swapModel.userDidSelect(provider: provider)
    }
}

// MARK: - SwapTokenSelectorOutput

extension TransferWithSwapModel: SwapTokenSelectorOutput {
    func swapTokenSelectorDidRequestUpdate(sender item: TokenSelectorItem) {
        swapModel.swapTokenSelectorDidRequestUpdate(sender: item)
    }

    func swapTokenSelectorDidRequestUpdate(destination item: TokenSelectorItem) {
        swapModel.swapTokenSelectorDidRequestUpdate(destination: item)
    }
}

// MARK: - SendFeeUpdater

extension TransferWithSwapModel: SendFeeUpdater {
    func updateFees() {
        if isTransferMode {
            transferModel.updateFees()
        } else {
            swapModel.updateFees()
        }
    }
}

// MARK: - SendFeeInput

extension TransferWithSwapModel: SendFeeInput {
    var selectedFee: TokenFee? {
        isTransferMode ? transferModel.selectedFee : swapModel.selectedFee
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.selectedFeePublisher : model.swapModel.selectedFeePublisher
            }
            .eraseToAnyPublisher()
    }

    var supportFeeSelection: Bool {
        isTransferMode ? transferModel.supportFeeSelection : swapModel.supportFeeSelection
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.supportFeeSelectionPublisher : model.swapModel.supportFeeSelectionPublisher
            }
            .eraseToAnyPublisher()
    }

    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.shouldShowFeeSelectorRow : model.swapModel.shouldShowFeeSelectorRow
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - SwapSummaryInput, SwapSummaryOutput

extension TransferWithSwapModel: SwapSummaryInput, SwapSummaryOutput {
    var isMaxAmountButtonHiddenPublisher: AnyPublisher<Bool, Never> {
        swapModel.isMaxAmountButtonHiddenPublisher
    }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer -> AnyPublisher<Bool, Never> in
                isTransfer ? .just(output: false) : model.swapModel.isUpdatingPublisher
            }
            .eraseToAnyPublisher()
    }

    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.isReadyToSendPublisher : model.swapModel.isReadyToSendPublisher
            }
            .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.isNotificationButtonIsLoading : model.swapModel.isNotificationButtonIsLoading
            }
            .eraseToAnyPublisher()
    }

    var isActionInProcessing: AnyPublisher<Bool, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.actionInProcessing : model.swapModel.isActionInProcessing
            }
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer -> AnyPublisher<SendSummaryTransactionData?, Never> in
                isTransfer ? model.transferModel.summaryTransactionDataPublisher : model.swapModel.summaryTransactionDataPublisher
            }
            .eraseToAnyPublisher()
    }

    func userDidRequestSwapSourceAndReceiveToken() {
        guard !isTransferMode else { return }
        swapModel.userDidRequestSwapSourceAndReceiveToken()
    }

    func userDidRequestMaxAmount() {
        swapModel.userDidRequestMaxAmount()
    }

    func userDidRequestSourceAmount(fraction: SwapAmountFraction) {
        swapModel.userDidRequestSourceAmount(fraction: fraction)
    }

    func userDidRequestSwap() {
        router?.performSwapAction()
    }
}

// MARK: - SendFinishInput

extension TransferWithSwapModel: SendFinishInput {
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

extension TransferWithSwapModel: SendBaseInput, SendBaseOutput {
    var actionInProcessing: AnyPublisher<Bool, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.actionInProcessing : model.swapModel.actionInProcessing
            }
            .eraseToAnyPublisher()
    }

    func actualizeInformation() {
        if isTransferMode {
            transferModel.actualizeInformation()
        }
    }

    func performAction() async throws -> TransactionDispatcherResult {
        if isTransferMode {
            return try await transferModel.performAction()
        }

        return try await swapModel.performAction()
    }
}

// MARK: - SendNotificationManagerInput

extension TransferWithSwapModel: SendNotificationManagerInput {
    var feeValues: AnyPublisher<[TokenFee], Never> {
        isTransferMode ? transferModel.feeValues : .just(output: [])
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.selectedTokenFeePublisher : model.swapModel.selectedFeePublisher
            }
            .eraseToAnyPublisher()
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.isFeeIncludedPublisher : .just(output: false)
            }
            .eraseToAnyPublisher()
    }

    var bsdkTransactionResultPublisher: AnyPublisher<Result<BSDKTransaction, Error>?, Never> {
        isTransferMode ? transferModel.bsdkTransactionResultPublisher : .just(output: nil)
    }
}

// MARK: - NotificationTapDelegate

extension TransferWithSwapModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        if isTransferMode {
            transferModel.didTapNotification(with: id, action: action)
        } else {
            swapModel.didTapNotification(with: id, action: action)
        }
    }
}

// MARK: - SendBaseDataBuilderInput

extension TransferWithSwapModel: SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? {
        isTransferMode ? transferModel.bsdkAmount : swapModel.bsdkAmount
    }

    var bsdkFee: BSDKFee? {
        isTransferMode ? transferModel.bsdkFee : swapModel.bsdkFee
    }

    var isFeeIncluded: Bool {
        isTransferMode ? transferModel.isFeeIncluded : swapModel.isFeeIncluded
    }
}

// MARK: - ApproveFlowDataProvider, ApproveOutput

extension TransferWithSwapModel: ApproveFlowDataProvider, ApproveOutput {
    func approveFlowInput() throws -> ApproveFlowInput {
        guard !isTransferMode else {
            throw SendApproveViewModelInputDataBuilderError.notSupported
        }

        return try swapModel.approveFlowInput()
    }

    func approveDidSendTransaction() {
        guard !isTransferMode else { return }
        swapModel.approveDidSendTransaction()
    }
}

// MARK: - TokenFeeProvidersManagerProviding

extension TransferWithSwapModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: TokenFeeProvidersManager? {
        isTransferMode ? transferModel.tokenFeeProvidersManager : swapModel.tokenFeeProvidersManager
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<TokenFeeProvidersManager, Never> {
        isTransferModePublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { model, isTransfer in
                isTransfer ? model.transferModel.tokenFeeProvidersManagerPublisher : model.swapModel.tokenFeeProvidersManagerPublisher
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - FeeSelectorOutput

extension TransferWithSwapModel: FeeSelectorOutput {
    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        if isTransferMode {
            transferModel.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption)
        } else {
            swapModel.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption)
        }
    }
}
