//
//  CommonSwapManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import TangemFoundation

class CommonSwapManager {
    // Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider
    private let interactor: ExpressInteractor

    // Private
    private var refreshDataTask: Task<Void, Error>?
    private var bag: Set<AnyCancellable> = []

    init(interactor: ExpressInteractor) {
        self.interactor = interactor

        bind()
    }
}

// MARK: - SwapManager

extension CommonSwapManager: SwapManager {
    var isSwapAvailable: Bool {
        expressAvailabilityProvider.canSwap(tokenItem: swappingPair.sender.tokenItem)
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

    var providersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> {
        statePublisher
            .withWeakCaptureOf(self)
            .asyncMap { manager, _ in
                await manager.interactor.getAllProviders()
            }
            .eraseToAnyPublisher()
    }

    var selectedProviderPublisher: AnyPublisher<ExpressAvailableProvider?, Never> {
        statePublisher
            .withWeakCaptureOf(self)
            .asyncMap { manager, _ in
                await manager.interactor.getSelectedProvider()
            }
            .eraseToAnyPublisher()
    }

    func update(amount: Decimal?) {
        interactor.update(amount: amount, by: .amountChange)
    }

    func update(destination: TokenItem?, address: String?) {
        let destinationWallet = destination.map {
            SwapManagerDestinationWallet(tokenItem: $0, address: address)
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
        try await interactor.send().result
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
        case .restriction(.hasPendingApproveTransaction, _),
             .permissionRequired,
             .previewCEX,
             .readyToSwap:
            restartTimer()
        case .idle, .loading, .restriction:
            stopTimer()
        }
    }

    func stopTimer() {
        AppLogger.info("Stop timer")
        refreshDataTask?.cancel()
    }

    func restartTimer() {
        AppLogger.info("Start timer")

        refreshDataTask?.cancel()
        refreshDataTask = runTask(in: self) {
            try await Task.sleep(seconds: 10)
            try Task.checkCancellation()

            AppLogger.info("Timer call autoupdate")
            $0.interactor.refresh(type: .refreshRates)
        }
    }
}
