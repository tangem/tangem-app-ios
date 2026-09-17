//
//  CommonPolymarketAccountGlobalStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class CommonPolymarketAccountGlobalStateProvider {
    private let criticalSection = OSAllocatedUnfairLock()
    private var unsafeHasPolymarketAccount: [AnyHashable: Bool] = [:]
    private var unsafeSubscriptions: [AnyHashable: AnyCancellable] = [:]

    fileprivate init() {}
}

// MARK: - PolymarketAccountGlobalStateProvider protocol conformance

extension CommonPolymarketAccountGlobalStateProvider: PolymarketAccountGlobalStateProvider {
    var hasPolymarketAccount: Bool {
        criticalSection {
            unsafeHasPolymarketAccount.values.contains(true)
        }
    }

    func register<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        let subscription = PolymarketAccountAggregator
            .polymarketAccountModelPublisher(from: manager)
            .flatMapLatest { accountModel -> AnyPublisher<Bool, Never> in
                guard let accountModel else { return .just(output: false) }

                return accountModel
                    .statePublisher
                    .map { $0?.isAccountVisible == true }
                    .eraseToAnyPublisher()
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { provider, hasPolymarket in
                provider.criticalSection {
                    provider.unsafeHasPolymarketAccount[identifier] = hasPolymarket
                }
            }

        criticalSection {
            unsafeSubscriptions[identifier] = subscription
        }
    }

    func unregister<U>(forIdentifier identifier: U) where U: Hashable {
        criticalSection {
            unsafeSubscriptions.removeValue(forKey: identifier)
            unsafeHasPolymarketAccount.removeValue(forKey: identifier)
        }
    }
}

// MARK: - Injection

extension InjectedValues {
    var polymarketAccountGlobalStateProvider: PolymarketAccountGlobalStateProvider {
        get { Self[PolymarketAccountGlobalStateProviderKey.self] }
        set { Self[PolymarketAccountGlobalStateProviderKey.self] = newValue }
    }
}

private struct PolymarketAccountGlobalStateProviderKey: InjectionKey {
    static var currentValue: PolymarketAccountGlobalStateProvider = CommonPolymarketAccountGlobalStateProvider()
}
