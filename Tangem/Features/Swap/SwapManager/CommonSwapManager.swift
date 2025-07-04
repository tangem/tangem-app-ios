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

class CommonSwapManager {
    private let interactor: ExpressInteractor

    init(interactor: ExpressInteractor) {
        self.interactor = interactor
    }
}

// MARK: - SwapManager

extension CommonSwapManager: SwapManager {
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

    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        interactor.state.map { state in
            switch state {
            case .idle, .loading, .restriction:
                return false
            case .permissionRequired:
                return true
            case .readyToSwap, .previewCEX:
                return true
            }
        }.eraseToAnyPublisher()
    }

    func update(amount: Decimal?) {
        interactor.update(amount: amount, by: .amountChange)
    }

    func update(destination: TokenItem?, address: String?) {
        let destinationWallet = destination.map {
            SwapManagerDestinationWallet(tokenItem: $0, address: address)
        }

        guard let destinationWallet else {
            // Clear destination
            // [REDACTED_TODO_COMMENT]
            return
        }

        interactor.update(destination: destinationWallet)
    }

    func update(provider: ExpressAvailableProvider) {
        interactor.updateProvider(provider: provider)
    }

    func updateFees() {
        interactor.refresh(type: .fee)
    }

    func send() async throws -> TransactionDispatcherResult {
        try await interactor.sendTransaction().dispatcherResult
    }
}

// MARK: - Private

private extension CommonSwapManager {}
