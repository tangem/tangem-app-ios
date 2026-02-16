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

    private let _availableProviders = CurrentValueSubject<LoadingResult<[ExpressAvailableProvider], any Error>?, Never>(.none)
    private let _selectedProvider = CurrentValueSubject<LoadingResult<ExpressAvailableProvider, any Error>?, Never>(.none)

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
}

// MARK: - Changes -> ExpressManager

extension SwapModel {}

// MARK: - Changes -> ExpressManager

extension SwapModel {
    func update(source wallet: SendSourceToken) {
        ExpressLogger.info("Will update source to \(wallet)")

        _sourceToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func update(receive wallet: SendSourceToken) {
        ExpressLogger.info("Will update receive to \(wallet as Any)")

        _receiveToken.send(.success(wallet))
        swappingPairDidChange()
    }

    func swappingPairDidChange() {
//        updateTask { owner in
//            guard let source = owner._sourceToken.value.value, let destination = owner._receiveToken.value.value else {
//                ExpressLogger.info("Source / Receive not found")
//                let provider = try await owner.expressManager.update(pair: .none)
//                return provider
//            }
//
//            let pair = ExpressManagerSwappingPair(source: source, destination: destination)
//            let provider = try await owner.expressManager.update(pair: pair)
//            return provider
//        }
    }

    func updateTask(block: @escaping (_ model: SwapModel) async throws -> ExpressAvailableProvider?) {
        updateTask?.cancel()
        updateTask = runTask(in: self, code: { input in
            do {
                switch try await block(input) {
                case .none:
                    input._availableProviders.send(.none)
                    input._selectedProvider.send(.none)

                case .some(let selectedProvider):
                    input._selectedProvider.send(.success(selectedProvider))
                }
            } catch {
                input._selectedProvider.send(.failure(error))
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
                let destination: SwapSourceToken = try await expressDestinationService.getDestination(source: source.tokenItem)
                update(receive: destination)

            case (_, .success(let destination)):
                try await expressPairsRepository.updatePairs(
                    for: destination.tokenItem.expressCurrency,
                    userWalletInfo: destination.userWalletInfo
                )

                _sourceToken.send(.loading)
                let source: SwapSourceToken = try await expressDestinationService.getSource(destination: destination.tokenItem)
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
            // return .noSourceTokens(destination: destination.tokenItem)
        } catch ExpressDestinationServiceError.destinationNotFound(let source) {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            ExpressLogger.info("Destination not found")
            _receiveToken.send(.failure(ExpressDestinationServiceError.destinationNotFound(source: source)))
            // return .noDestinationTokens(source: source.tokenItem)
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

// MARK: - SendSourceTokenInput

extension SwapModel: SendSourceTokenInput {
    var sourceToken: LoadingResult<SendSourceToken, any Error> { _sourceToken.value }

    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        _sourceToken.eraseToAnyPublisher()
    }
}

// MARK: - SendSourceTokenOutput

extension SwapModel: SendSourceTokenOutput {
    func userDidSelect(sourceToken: SendSourceToken) {
        _sourceToken.send(.success(sourceToken))
    }
}

// MARK: - SendSourceTokenAmountInput

extension SwapModel: SendSourceTokenAmountInput {
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
}

// MARK: - SendSourceTokenAmountOutput

extension SwapModel: SendSourceTokenAmountOutput {
    func sourceAmountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendReceiveTokenInput

extension SwapModel: SendReceiveTokenInput {
    var isReceiveTokenSelectionAvailable: Bool {
        true
    }

    var receiveToken: LoadingResult<any SendReceiveToken, any Error> {
        _receiveToken.value.mapValue { $0 as SendReceiveToken }
    }

    var receiveTokenPublisher: AnyPublisher<LoadingResult<any SendReceiveToken, any Error>, Never> {
        _receiveToken.map { $0.mapValue { $0 as SendReceiveToken }}.eraseToAnyPublisher()
    }
}

// MARK: - SendReceiveTokenOutput

extension SwapModel: SendReceiveTokenOutput {
    func userDidRequestClearSelection() {
        assertionFailure("SwapModel doesn't support receiving token clearing")
    }

    func userDidRequestSelect(receiveToken: SendReceiveToken, selected: @escaping (Bool) -> Void) {
        // _receiveToken.send(newReceiveToken)
    }
}

// MARK: - SendReceiveTokenAmountInput

extension SwapModel: SendReceiveTokenAmountInput {
    var receiveAmount: LoadingResult<SendAmount, any Error> {
        mapToReceiveSendAmount(state: _selectedProvider.value?.value?.getState())
    }

    var receiveAmountPublisher: AnyPublisher<TangemFoundation.LoadingResult<SendAmount, any Error>, Never> {
        _selectedProvider
            .withWeakCaptureOf(self)
            .map { $0.mapToReceiveSendAmount(state: $1?.value?.getState()) }
            .eraseToAnyPublisher()
    }

    var highPriceImpact: HighPriceImpactCalculator.Result? {
        get async {
            try? await mapToHighPriceImpactCalculatorResult(
                sourceTokenAmount: sourceAmount.value,
                receiveTokenAmount: receiveAmount.value,
                provider: _selectedProvider.value?.value?.provider
            )
        }
    }

    var highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never> {
        Publishers.CombineLatest3(
            sourceAmountPublisher.compactMap { $0.value },
            receiveAmountPublisher.compactMap { $0.value },
            selectedExpressProviderPublisher.compactMap { $0?.provider }
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

    private func mapToReceiveSendAmount(state: ExpressProviderManagerState?) -> LoadingResult<SendAmount, any Error> {
        guard let quote = state?.quote else {
            return .failure(SendAmountError.noAmount)
        }

        let fiat = receiveToken.value?.tokenItem.currencyId.flatMap { currencyId in
            balanceConverter.convertToFiat(quote.expectAmount, currencyId: currencyId)
        }
        return .success(.init(type: .typical(crypto: quote.expectAmount, fiat: fiat)))
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
        _availableProviders.value?.value ?? []
    }

    var expressProvidersPublisher: AnyPublisher<[TangemExpress.ExpressAvailableProvider], Never> {
        _availableProviders.compactMap { $0?.value }.eraseToAnyPublisher()
    }

    var selectedExpressProvider: ExpressAvailableProvider? {
        _selectedProvider.value?.value
    }

    var selectedExpressProviderPublisher: AnyPublisher<ExpressAvailableProvider?, Never> {
        _selectedProvider.map { $0?.value }.eraseToAnyPublisher()
    }
}

// MARK: - SendSwapProvidersOutput

extension SwapModel: SendSwapProvidersOutput {
    func userDidSelect(provider: ExpressAvailableProvider) {
        _selectedProvider.send(.success(provider))
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
}

// MARK: - TokenFeeProvidersManagerProviding

extension SwapModel: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: (any TokenFeeProvidersManager)? {
        _selectedProvider.value?.value?.manager.feeProvider as? TokenFeeProvidersManager
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<any TokenFeeProvidersManager, Never> {
        _selectedProvider
            .compactMap { $0?.value?.manager as? TokenFeeProvidersManager }
            .eraseToAnyPublisher()
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
    func stopSwapProvidersAutoUpdateTimer() {
        // swapManager.stopTimer()
    }

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
        nil //  _amount.value?.crypto.map { makeAmount(decimal: $0) }
    }

    var bsdkFee: BSDKFee? {
        selectedFee?.value.value
    }

    var isFeeIncluded: Bool {
        false
    }
}

extension SwapModel {
    enum SwappingPairState {
        case loading
    }

    typealias Source = LoadingResult<SendSourceToken, Error>
    typealias Destination = LoadingResult<SendSourceToken, Error>

    struct SwappingPair {
        var sender: Source
        var destination: Destination?
    }
}
