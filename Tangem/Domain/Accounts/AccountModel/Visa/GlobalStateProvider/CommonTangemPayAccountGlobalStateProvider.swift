//
//  CommonTangemPayAccountGlobalStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonTangemPayAccountGlobalStateProvider {
    private let criticalSection = OSAllocatedUnfairLock()
    private var unsafeHasTangemPayAccount: [AnyHashable: Bool] = [:]
    private var unsafeSubscriptions: [AnyHashable: AnyCancellable] = [:]

    fileprivate init() {}
}

// MARK: - TangemPayAccountGlobalStateProvider protocol conformance

extension CommonTangemPayAccountGlobalStateProvider: TangemPayAccountGlobalStateProvider {
    var hasTangemPayAccount: Bool {
        criticalSection {
            unsafeHasTangemPayAccount.values.contains(true)
        }
    }

    func register<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        let subscription = manager
            .accountModelsPublisher
            .map { accountModels in
                accountModels.contains { accountModel in
                    if case .tangemPay = accountModel { return true }
                    return false
                }
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { provider, hasTangemPay in
                provider.criticalSection {
                    provider.unsafeHasTangemPayAccount[identifier] = hasTangemPay
                }
            }

        criticalSection {
            unsafeSubscriptions[identifier] = subscription
        }
    }

    func unregister<U>(forIdentifier identifier: U) where U: Hashable {
        criticalSection {
            unsafeSubscriptions.removeValue(forKey: identifier)
            unsafeHasTangemPayAccount.removeValue(forKey: identifier)
        }
    }
}

// MARK: - Injection

extension InjectedValues {
    var tangemPayAccountGlobalStateProvider: TangemPayAccountGlobalStateProvider {
        get { Self[TangemPayAccountGlobalStateProviderKey.self] }
        set { Self[TangemPayAccountGlobalStateProviderKey.self] = newValue }
    }
}

private struct TangemPayAccountGlobalStateProviderKey: InjectionKey {
    static var currentValue: TangemPayAccountGlobalStateProvider = CommonTangemPayAccountGlobalStateProvider()
}
