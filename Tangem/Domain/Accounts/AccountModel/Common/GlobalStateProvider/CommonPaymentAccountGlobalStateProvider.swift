//
//  CommonPaymentAccountGlobalStateProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class CommonPaymentAccountGlobalStateProvider {
    private let criticalSection = OSAllocatedUnfairLock()
    private var unsafeState: [AnyHashable: PaymentAccountState] = [:]
    private var unsafeSubscriptions: [AnyHashable: AnyCancellable] = [:]

    fileprivate init() {}
}

// MARK: - PaymentAccountGlobalStateProvider protocol conformance

extension CommonPaymentAccountGlobalStateProvider: PaymentAccountGlobalStateProvider {
    var hasTangemPayAccount: Bool {
        criticalSection {
            unsafeState.values.contains { $0.hasTangemPay }
        }
    }

    var hasVirtualAccount: Bool {
        criticalSection {
            unsafeState.values.contains { $0.hasVirtualAccount }
        }
    }

    func register<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        let subscription = manager
            .accountModelsPublisher
            .map { accountModels in
                var hasTangemPay = false
                var hasVirtualAccount = false

                for accountModel in accountModels {
                    switch accountModel {
                    case .tangemPay:
                        hasTangemPay = true
                    case .virtualAccount:
                        hasVirtualAccount = true
                    case .standard:
                        break
                    }
                }

                return PaymentAccountState(hasTangemPay: hasTangemPay, hasVirtualAccount: hasVirtualAccount)
            }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { provider, state in
                provider.criticalSection {
                    provider.unsafeState[identifier] = state
                }
            }

        criticalSection {
            unsafeSubscriptions[identifier] = subscription
        }
    }

    func unregister<U>(forIdentifier identifier: U) where U: Hashable {
        criticalSection {
            unsafeSubscriptions.removeValue(forKey: identifier)
            unsafeState.removeValue(forKey: identifier)
        }
    }
}

// MARK: - PaymentAccountState

private struct PaymentAccountState: Equatable {
    var hasTangemPay: Bool = false
    var hasVirtualAccount: Bool = false
}

// MARK: - Injection

extension InjectedValues {
    var paymentAccountGlobalStateProvider: PaymentAccountGlobalStateProvider {
        get { Self[PaymentAccountGlobalStateProviderKey.self] }
        set { Self[PaymentAccountGlobalStateProviderKey.self] = newValue }
    }
}

private struct PaymentAccountGlobalStateProviderKey: InjectionKey {
    static var currentValue: PaymentAccountGlobalStateProvider = CommonPaymentAccountGlobalStateProvider()
}
