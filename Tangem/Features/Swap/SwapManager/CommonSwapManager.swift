//
//  CommonSwapManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation

class CommonSwapManager {
    // Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let userWalletConfig: any UserWalletConfig
    private let interactor: ExpressInteractor

    // Private
    private var refreshDataTask: Task<Void, Error>?
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletConfig: any UserWalletConfig,
        interactor: ExpressInteractor
    ) {
        self.userWalletConfig = userWalletConfig
        self.interactor = interactor

        bind()
    }
}

// MARK: - SwapManager

extension CommonSwapManager: SwapManager {
    var isSwapAvailable: Bool {
        guard let source = swappingPair.sender.value else {
            return false
        }

        let canSwap = expressAvailabilityProvider.canSwap(tokenItem: source.tokenItem)
        let isMultiCurrency = userWalletConfig.hasFeature(.multiCurrency)

        return canSwap && isMultiCurrency
    }

    var swappingPair: SwapManagerSwappingPair {
        interactor.getSwappingPair()
    }

    var swappingPairPublisher: AnyPublisher<SwapManagerSwappingPair, Never> {
        interactor.swappingPair
    }

    var state: SwapManagerState {
        interactor.getState()
    }

    var statePublisher: AnyPublisher<ExpressInteractor.State, Never> {
        interactor.state
    }

    var providers: [ExpressAvailableProvider] {
        get async { await interactor.getAllProviders() }
    }

    var providersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        interactor.providersPublisher()
    }

    var selectedProviderPublisher: AnyPublisher<ExpressAvailableProvider?, Never> {
        interactor.selectedProviderPublisher()
    }

    func update(amount: Decimal?) {
        interactor.update(amount: amount, by: .amountChange)
    }

    func update(
        userWalletId: UserWalletId,
        destination: TokenItem?,
        address: String?,
        additionalField: SendDestinationAdditionalField,
        tokenHeader: ExpressInteractorTokenHeader?,
        accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    ) {
        let extraId: String? = switch additionalField {
        case .filled(_, let extraId, _): extraId
        default: nil
        }

        let destinationWallet = destination.map {
            SwapDestinationWalletWrapper(
                userWalletId: userWalletId,
                tokenItem: $0,
                address: address,
                extraId: extraId,
                tokenHeader: tokenHeader,
                accountModelAnalyticsProvider: accountModelAnalyticsProvider
            )
        }

        interactor.update(destination: destinationWallet)
    }

    func update(provider: ExpressAvailableProvider) {
        interactor.updateProvider(provider: provider)
    }

    func update() {
        interactor.refresh(type: .full)
    }

    func updateFees() {
        interactor.refresh(type: .fee)
    }

    func send() async throws -> TransactionDispatcherResult {
        do {
            // Stop timer while sending
            stopTimer()

            let result = try await interactor.send(shouldTrackAnalytics: false).result
            return result
        } catch TransactionDispatcherResult.Error.userCancelled {
            restartTimer()
            throw TransactionDispatcherResult.Error.userCancelled
        } catch {
            throw error
        }
    }

    func stopTimer() {
        AppLogger.info("Stop timer")
        refreshDataTask?.cancel()
    }
}

// MARK: - SendApproveDataBuilderInput

extension CommonSwapManager: SendApproveDataBuilderInput {
    var selectedExpressProvider: ExpressProvider? {
        state.context?.provider
    }

    var approveViewModelInput: (any ApproveViewModelInput)? {
        interactor
    }

    var selectedPolicy: ApprovePolicy? {
        guard case .permissionRequired(let permissionRequired, _, _) = interactor.getState() else {
            return nil
        }

        return permissionRequired.policy
    }
}

// MARK: - TokenFeeProvidersManagerProviding (ExpressInteractor Proxy)

extension CommonSwapManager: TokenFeeProvidersManagerProviding {
    var tokenFeeProvidersManager: TokenFeeProvidersManager? {
        interactor.tokenFeeProvidersManager
    }

    var tokenFeeProvidersManagerPublisher: AnyPublisher<any TokenFeeProvidersManager, Never> {
        interactor.tokenFeeProvidersManagerPublisher
    }
}

// MARK: - TokenFeeProvidersManagerProviding (ExpressInteractor Proxy)

extension CommonSwapManager: FeeSelectorOutput {
    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption) {
        interactor.userDidFinishSelection(feeTokenItem: feeTokenItem, feeOption: feeOption)
    }
}

// MARK: - Private

private extension CommonSwapManager {
    func bind() {
        // Timer
        statePublisher
            .withWeakCaptureOf(self)
            .sink { $0.updateTimer(state: $1) }
            .store(in: &bag)
    }

    func updateTimer(state: SwapManagerState) {
        switch state {
        case .restriction(.hasPendingApproveTransaction, _, _),
             .permissionRequired,
             .previewCEX,
             .readyToSwap:
            restartTimer()
        case .idle, .loading, .preloadRestriction, .requiredRefresh, .restriction, .runtimeRestriction:
            stopTimer()
        }
    }

    func restartTimer() {
        AppLogger.info("Start timer")

        refreshDataTask?.cancel()
        refreshDataTask = runTask(in: self) {
            try await Task.sleep(for: .seconds(10))
            try Task.checkCancellation()

            AppLogger.info("Timer call autoupdate")
            $0.interactor.refresh(type: .refreshRates)
        }
    }
}
