//
//  SwapModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation

protocol SwapModelRoutable: AnyObject {
    func openNetworkCurrency()
    func openApproveSheet()
    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel)
}

final class SwapModel {
    // MARK: - Data

    private let _sourceToken: CurrentValueSubject<LoadingResult<SendSourceToken, any Error>, Never>
    private let _receiveToken: CurrentValueSubject<LoadingResult<SendSourceToken, any Error>, Never>
    private let _amount: CurrentValueSubject<SendAmount?, Never>

    private let _providersState = CurrentValueSubject<ProvidersState, Never>(.idle)

    private let _transactionTime = PassthroughSubject<Date?, Never>()
    private let _transactionURL = PassthroughSubject<URL?, Never>()
    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    weak var router: SendModelRoutable?
    weak var alertPresenter: SendViewAlertPresenter?

    // MARK: - Private injections

    private let expressManager: ExpressManager
    private let expressPairsRepository: ExpressPairsRepository
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let expressDestinationService: ExpressDestinationService
    private let expressAPIProvider: ExpressAPIProvider

    private let balanceConverter = BalanceConverter()
    private var updateTask: Task<Void, Never>?

    init(
        sourceToken: SendSourceToken?,
        receiveToken: SendSourceToken?,
        expressManager: ExpressManager,
        expressPairsRepository: ExpressPairsRepository,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressDestinationService: ExpressDestinationService,
        expressAPIProvider: ExpressAPIProvider
    ) {
        self.expressManager = expressManager
        self.expressPairsRepository = expressPairsRepository
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.expressAPIProvider = expressAPIProvider

        _sourceToken = .init(sourceToken.map { .success($0) } ?? .loading)
        _receiveToken = .init(receiveToken.map { .success($0) } ?? .loading)
        _amount = .init(.none)

        Task { await initialLoading() }
    }

    deinit {
        ExpressLogger.debug("deinit SwapModel")
    }
}

// MARK: - Changes -> ExpressManager

extension SwapModel {
    func update(sourceAmount: SendAmount?) {
        ExpressLogger.info("Will update source amount to \(sourceAmount as Any)")
        _amount.send(sourceAmount)

        updateTask(loadingType: .rates) { expressManager in
            if sourceAmount != nil {
                // Add some debounce
                try await Task.sleep(for: .seconds(1))
            }

            return try await expressManager.update(amount: sourceAmount?.crypto, by: .amountChange)
        }
    }

    func update(source wallet: SendSourceToken) {
        ExpressLogger.info("Will update source to \(wallet.tokenItem)")

        _sourceToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func update(receive wallet: SendSourceToken) {
        ExpressLogger.info("Will update receive to \(wallet.tokenItem)")

        _receiveToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func swappingPairDidChange() {
        updateTask(loadingType: .providers) { [weak self] expressManager in
            guard let source = self?._sourceToken.value.value, let destination = self?._receiveToken.value.value else {
                ExpressLogger.info("Source / Receive not found")
                let provider: ExpressManagerUpdatingResult = try await expressManager.update(pair: .none)
                return provider
            }

            let pair = ExpressManagerSwappingPair(source: source, destination: destination)
            let provider: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)
            return provider
        }
    }

    func updateTask(loadingType: LoadingType, block: @escaping (_ manager: ExpressManager) async throws -> ExpressManagerUpdatingResult?) {
        updateTask?.cancel()
        updateTask = runTask(in: self, code: { input in
            do {
                input._providersState.send(.loading(loadingType))
                let result = try await block(input.expressManager)

                switch result {
                case .none:
                    input._providersState.send(.idle)

                case .some(let selectedProvider):
                    input._providersState.send(.loaded(selectedProvider))
                }
            } catch is CancellationError {
                ExpressLogger.debug("updateTask was cancelled")
                // Do nothing
            } catch {
                input._providersState.send(.failure(error))
            }
        })
    }
}

// MARK: - Initial (pair) loading

extension SwapModel {
    func initialLoading() async {
        do {
            switch (_sourceToken.value, _receiveToken.value) {
            case (.success, .success):
                // All already set
                swappingPairDidChange()

            case (.success(let source), _):
                try await expressPairsRepository.updatePairs(
                    for: source.tokenItem.expressCurrency,
                    userWalletInfo: source.userWalletInfo
                )

                _receiveToken.send(.loading)
                let destination: SendSourceToken = try await expressDestinationService.getDestination(source: source.tokenItem)
                update(receive: destination)

            case (_, .success(let destination)):
                try await expressPairsRepository.updatePairs(
                    for: destination.tokenItem.expressCurrency,
                    userWalletInfo: destination.userWalletInfo
                )

                _sourceToken.send(.loading)
                let source: SendSourceToken = try await expressDestinationService.getSource(destination: destination.tokenItem)
                update(source: source)

            default:
                assertionFailure("Wrong case. Check implementation")
                _sourceToken.send(.failure(ExpressInteractorError.sourceNotFound))
                _receiveToken.send(.failure(ExpressInteractorError.destinationNotFound))
            }
        } catch ExpressDestinationServiceError.sourceNotFound(let destination) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Source not found")
            _sourceToken.send(.failure(ExpressDestinationServiceError.sourceNotFound(destination: destination)))

        } catch ExpressDestinationServiceError.destinationNotFound(let source) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Destination not found")
            _receiveToken.send(.failure(ExpressDestinationServiceError.destinationNotFound(source: source)))

        } catch {
            ExpressLogger.info("Update pairs failed with error: \(error)")

            if _receiveToken.value.isLoading {
                _receiveToken.send(.failure(error))
            }

            if _sourceToken.value.isLoading {
                _sourceToken.send(.failure(error))
            }
        }
    }
}

// MARK: - SendSourceTokenInput, SendSourceTokenOutput

extension SwapModel: SendSourceTokenInput, SendSourceTokenOutput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> { _sourceToken.value }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        _sourceToken.eraseToAnyPublisher()
    }

    func userDidSelect(sourceToken: SendSourceToken) {
        _sourceToken.send(.success(sourceToken))
    }
}

// MARK: - SendSourceTokenAmountInput

extension SwapModel: SendSourceTokenAmountInput, SendSourceTokenAmountOutput {
    var sourceAmount: LoadingResult<SendAmount, any Error> {
        switch _amount.value {
        case .none: .failure(SendAmountError.noAmount)
        case .some(let amount): .success(amount)
        }
    }

    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        _amount.map { amount in
            switch amount {
            case .none: .failure(SendAmountError.noAmount)
            case .some(let amount): .success(amount)
            }
        }.eraseToAnyPublisher()
    }

    func sourceAmountDidChanged(amount: SendAmount?) {
        update(sourceAmount: amount)
    }
}

// MARK: - SendReceiveTokenInput, SendReceiveTokenOutput

extension SwapModel: SendReceiveTokenInput, SendReceiveTokenOutput {
    var isReceiveTokenSelectionAvailable: Bool {
        true
    }

    var receiveToken: LoadingResult<any SendReceiveToken, any Error> {
        _receiveToken.value.mapValue { $0 as SendReceiveToken }
    }

    var receiveTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        _receiveToken.map { $0.mapValue { $0 as SendReceiveToken }}.eraseToAnyPublisher()
    }

    func userDidRequestClearSelection() {
        assertionFailure("SwapModel doesn't support receiving token clearing")
    }

    func userDidRequestSelect(receiveToken: SendReceiveToken, selected: @escaping (Bool) -> Void) {
        guard let receiveToken = receiveToken as? SendSourceToken else {
            return selected(false)
        }

        _receiveToken.send(.success(receiveToken))
        selected(true)
    }
}

// MARK: - SendReceiveTokenAmountInput

extension SwapModel: SendReceiveTokenAmountInput {
    var receiveAmount: LoadingResult<SendAmount, any Error> {
        mapToReceiveSendAmount(state: _providersState.value)
    }

    var receiveAmountPublisher: AnyPublisher<LoadingResult<SendAmount, any Error>, Never> {
        _providersState
            .withWeakCaptureOf(self)
            .map { $0.mapToReceiveSendAmount(state: $1) }
            .eraseToAnyPublisher()
    }

    var highPriceImpact: HighPriceImpactCalculator.Result? {
        get async {
            try? await mapToHighPriceImpactCalculatorResult(
                sourceTokenAmount: sourceAmount.value,
                receiveTokenAmount: receiveAmount.value,
                provider: selectedExpressProvider?.value?.provider
            )
        }
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        Publishers.CombineLatest3(
            sourceAmountPublisher.compactMap { $0.value },
            receiveAmountPublisher.compactMap { $0.value },
            selectedExpressProviderPublisher.compactMap { $0?.value?.provider }
        )
        .withWeakCaptureOf(self)
        .setFailureType(to: Error.self)
        .asyncTryMap {
            try await $0.mapToHighPriceImpactCalculatorResult(
                sourceTokenAmount: $1.0,
                receiveTokenAmount: $1.1,
                provider: $1.2
            )
        }
        .replaceError(with: nil)
        .eraseToAnyPublisher()
    }

    private func mapToReceiveSendAmount(state: ProvidersState) -> LoadingResult<SendAmount, any Error> {
        switch state {
        case .loading(.providers), .loading(.rates):
            return .loading

        case .idle, .loading: // Another loading has to be filtered
            return .failure(SendAmountError.noAmount)

        case .failure(let error):
            return .failure(error)

        case .loaded(let result):
            guard let quote = result.selected?.getState().quote else {
                return .failure(SendAmountError.noAmount)
            }

            let fiat = receiveToken.value?.tokenItem.currencyId.flatMap { currencyId in
                balanceConverter.convertToFiat(quote.expectAmount, currencyId: currencyId)
            }
            return .success(.init(type: .typical(crypto: quote.expectAmount, fiat: fiat)))
        }
    }

    private func mapToHighPriceImpactCalculatorResult(
        sourceTokenAmount: SendAmount?,
        receiveTokenAmount: SendAmount?,
        provider: ExpressProvider?
    ) async throws -> HighPriceImpactCalculator.Result? {
        guard let source = sourceToken.value,
              let receive = receiveToken.value,
              let sourceTokenFiatAmount = sourceTokenAmount?.fiat,
              let receiveTokenFiatAmount = receiveTokenAmount?.fiat,
              let provider = provider else {
            return nil
        }

        let impactCalculator = HighPriceImpactCalculator(
            source: source.tokenItem,
            destination: receive.tokenItem
        )

        let result = try await impactCalculator.isHighPriceImpact(
            provider: provider,
            sourceFiatAmount: sourceTokenFiatAmount,
            destinationFiatAmount: receiveTokenFiatAmount
        )

        return result
    }
}

// MARK: - SendSwapProvidersInput

extension SwapModel: SendSwapProvidersInput {
    var expressProviders: [ExpressAvailableProvider] {
        _providersState.value.providers
    }

    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        _providersState.compactMap { $0.providers }.eraseToAnyPublisher()
    }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? {
        mapToLoadingExpressAvailableProvider(providersState: _providersState.value)
    }

    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> {
        _providersState
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadingExpressAvailableProvider(providersState: $1) }
            .eraseToAnyPublisher().eraseToAnyPublisher()
    }

    private func mapToLoadingExpressAvailableProvider(providersState: ProvidersState) -> LoadingResult<ExpressAvailableProvider, any Error>? {
        switch providersState {
        case .idle: return .none
        case .failure(let error): return .failure(error)
        case .loading(.rates): return .loading
        case .loading: return .none
        case .loaded(let result): return result.selected.map { .success($0) }
        }
    }
}

// MARK: - SendSwapProvidersOutput

extension SwapModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        updateTask(loadingType: .provider) { expressManager in
            try await expressManager.updateSelectedProvider(provider: provider)
        }
    }
}

// MARK: - TokenFeeProvidersManagerProviding

extension SwapModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: (any TokenFeeProvidersManager)? {
        selectedExpressProvider?.value?.manager.feeProvider as? TokenFeeProvidersManager
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<any TokenFeeProvidersManager, Never> {
        selectedExpressProviderPublisher
            .compactMap { $0?.value?.manager.feeProvider as? TokenFeeProvidersManager }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFeeInput

extension SwapModel: SendFeeInput {
    var selectedFee: TokenFee? {
        tokenFeeProvidersManager?.selectedTokenFee
    }

    var selectedFeePublisher: AnyPublisher<TokenFee, Never> {
        tokenFeeProvidersManagerPublisher
            .flatMapLatest { $0.selectedTokenFeePublisher }
            .eraseToAnyPublisher()
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        tokenFeeProvidersManagerPublisher
            .flatMapLatest { $0.supportFeeSelectionPublisher }
            .eraseToAnyPublisher()
    }

    var shouldShowFeeSelectorRow: AnyPublisher<Bool, Never> {
        selectedExpressProviderPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToShouldShowFeeSelectorRow(selectedProvider: $1) }
            .eraseToAnyPublisher().eraseToAnyPublisher()
    }

    private func mapToShouldShowFeeSelectorRow(selectedProvider: LoadingResult<ExpressAvailableProvider, any Error>?) -> Bool {
        switch selectedProvider?.value?.getState() {
        case .preview, .ready: return true
        default: return false
        }
    }
}

// MARK: - FeeSelectorOutput

extension SwapModel: FeeSelectorOutput {
    func userDidDismissFeeSelection() {
        tokenFeeProvidersManager?.selectedFeeProvider.updateFees()
    }

    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        tokenFeeProvidersManager?.updateSelectedFeeProvider(feeTokenItem: feeTokenItem)
        tokenFeeProvidersManager?.update(feeOption: feeOption)
    }
}

// MARK: - SendSummaryInput, SendSummaryOutput

extension SwapModel: SendSummaryInput, SendSummaryOutput {
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { $0.0.isReadyToSend() }
            .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        tokenFeeProvidersManagerPublisher
            .flatMapLatest { $0.selectedFeeProviderPublisher }
            .flatMapLatest { $0.statePublisher.map(\.isLoading) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { $0.0.summaryTransactionData() }
            .eraseToAnyPublisher()
    }

    private func isReadyToSend() -> AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    private func summaryTransactionData() -> AnyPublisher<SendSummaryTransactionData?, Never> {
        .just(output: .none)
    }
}

// MARK: - SendFinishInput

extension SwapModel: SendFinishInput {
    var transactionSentDate: AnyPublisher<Date, Never> {
        _transactionTime.compactMap { $0 }.first().eraseToAnyPublisher()
    }

    var transactionURL: AnyPublisher<URL?, Never> {
        _transactionURL.eraseToAnyPublisher()
    }
}

// MARK: - SendBaseInput, SendBaseOutput

extension SwapModel: SendBaseInput, SendBaseOutput {
    func stopSwapProvidersAutoUpdateTimer() {}

    var actionInProcessing: AnyPublisher<Bool, Never> {
        _isSending.eraseToAnyPublisher()
    }

    func actualizeInformation() {}

    func performAction() async throws -> TransactionDispatcherResult {
        throw TransactionDispatcherResult.Error.actionNotSupported
    }
}

// MARK: - SendBaseDataBuilderInput

extension SwapModel: SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? {
        guard let crypto = sourceAmount.value?.crypto,
              let source = sourceToken.value else {
            return nil
        }

        return BSDKAmount(with: source.tokenItem.blockchain, type: source.tokenItem.amountType, value: crypto)
    }

    var bsdkFee: BSDKFee? {
        selectedFee?.value.value
    }

    var isFeeIncluded: Bool {
        false
    }
}

extension SwapModel {
    enum ProvidersState {
        case idle
        case loading(LoadingType)
        /// Error only for case when all providers didn't loaded
        case failure(Error)
        case loaded(ExpressManagerUpdatingResult)

        var selectedProvider: ExpressAvailableProvider? {
            switch self {
            case .loaded(let result): result.selected
            default: nil
            }
        }

        var providers: [ExpressAvailableProvider] {
            switch self {
            case .loaded(let result): result.providers
            default: []
            }
        }
    }

    enum LoadingType {
        case providers
        case provider
        case rates
        case autoupdate
        case fee
    }
}
