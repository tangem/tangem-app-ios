//
//  PolymarketFastTradingRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

struct PolymarketFastTradingContext {
    let signingRouter: PolymarketOrderSigningRouting
    let service: PolymarketFastTradingServicing
}

final class PolymarketFastTradingRegistry {
    typealias MakeContext = @MainActor (any UserWalletModel) -> PolymarketFastTradingContext

    private let isAvailable: () -> Bool
    private let makeContext: MakeContext
    private let state = OSAllocatedUnfairLock<State>(uncheckedState: State())
    private var walletEventsSubscription: AnyCancellable?

    init(
        walletEvents: AnyPublisher<UserWalletRepositoryEvent, Never>,
        isAvailable: @escaping () -> Bool = PolymarketSessionKeyFactory.isFastTradingAvailable,
        makeContext: @escaping MakeContext = { PolymarketSessionKeyFactory().makeFastTradingContext(for: $0) }
    ) {
        self.isAvailable = isAvailable
        self.makeContext = makeContext

        walletEventsSubscription = walletEvents.sink { [weak self] event in
            self?.handle(event)
        }
    }

    @MainActor
    func context(for userWalletModel: any UserWalletModel) -> PolymarketFastTradingContext? {
        guard isAvailable() else {
            return nil
        }

        let userWalletId = userWalletModel.userWalletId
        let (stored, generation) = state.withLockUnchecked { ($0.contexts[userWalletId], $0.generation) }

        if let stored {
            return stored
        }

        let made = makeContext(userWalletModel)

        return state.withLockUnchecked { state in
            if let context = state.contexts[userWalletId] {
                return context
            }

            if state.generation == generation {
                state.contexts[userWalletId] = made
            }

            return made
        }
    }
}

// MARK: - State

private extension PolymarketFastTradingRegistry {
    struct State {
        var contexts: [UserWalletId: PolymarketFastTradingContext] = [:]
        var generation = 0
    }
}

// MARK: - Wallet lifecycle

private extension PolymarketFastTradingRegistry {
    func handle(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .deleted(let userWalletIds, _):
            let dropped = dropContexts { contexts in
                userWalletIds.compactMap { contexts.removeValue(forKey: $0) }
            }

            Task { @MainActor in
                dropped.forEach { $0.service.cancelWork() }
            }
        case .locked:
            dropContexts { contexts in
                defer { contexts.removeAll() }
                return Array(contexts.values)
            }
        case .unlocked, .inserted, .unlockedWallet, .selected, .reordered:
            break
        }
    }

    @discardableResult
    func dropContexts(_ remove: (inout [UserWalletId: PolymarketFastTradingContext]) -> [PolymarketFastTradingContext]) -> [PolymarketFastTradingContext] {
        state.withLockUnchecked { state in
            state.generation += 1
            return remove(&state.contexts)
        }
    }
}

// MARK: - Injection

private struct PolymarketFastTradingRegistryKey: InjectionKey {
    static var currentValue = PolymarketFastTradingRegistry(walletEvents: InjectedValues[\.userWalletRepository].eventProvider)
}

extension InjectedValues {
    var polymarketFastTradingRegistry: PolymarketFastTradingRegistry {
        get { Self[PolymarketFastTradingRegistryKey.self] }
        set { Self[PolymarketFastTradingRegistryKey.self] = newValue }
    }
}
