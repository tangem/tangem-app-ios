//
//  CommonCryptoAccountsGlobalStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class CommonCryptoAccountsGlobalStateProvider {
    private let didChangeSubject = PassthroughSubject<Void, Never>()
    private let criticalSection = OSAllocatedUnfairLock()
    private var unsafeCryptoAccountsCount: [AnyHashable: Int] = [:]
    private var unsafeSubscriptions: [AnyHashable: AnyCancellable] = [:]

    fileprivate init() {}
}

// MARK: - CryptoAccountsGlobalStateProvider protocol conformance

extension CommonCryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider {
    func register<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        let subscription = manager
            .cryptoAccountModelsPublisher
            .map(\.count)
            .withWeakCaptureOf(self)
            .sink { provider, count in
                provider.onCryptoAccountsCountChanged(identifier: identifier, count: count)
            }

        criticalSection {
            unsafeSubscriptions[identifier] = subscription
        }
    }

    func unregister<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        let hasChanges = criticalSection {
            unsafeSubscriptions.removeValue(forKey: identifier)
            let removedValue = unsafeCryptoAccountsCount.removeValue(forKey: identifier)

            return removedValue != nil
        }

        if hasChanges {
            didChangeSubject.send()
        }
    }

    func globalCryptoAccountsState() -> CryptoAccounts.State {
        criticalSection {
            Self.globalState(for: unsafeCryptoAccountsCount)
        }
    }

    func globalCryptoAccountsStatePublisher() -> AnyPublisher<CryptoAccounts.State, Never> {
        didChangeSubject
            .prepend(())
            .withWeakCaptureOf(self)
            .map { provider, _ in
                return provider.globalCryptoAccountsState()
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private static func globalState(for cryptoAccountsCount: [AnyHashable: Int]) -> CryptoAccounts.State {
        // If we have at least one wallet with more than one crypto account, then the global state is `.multiple`
        return cryptoAccountsCount.values.contains { $0 > 1 } ? .multiple : .single
    }

    private func onCryptoAccountsCountChanged<T>(identifier: T, count: Int) where T: Hashable {
        let hasChanges = criticalSection {
            let oldValue = unsafeCryptoAccountsCount[identifier]
            unsafeCryptoAccountsCount[identifier] = count

            return oldValue != count
        }

        if hasChanges {
            didChangeSubject.send()
        }
    }
}

// MARK: - Injection

extension InjectedValues {
    var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider {
        get { Self[CryptoAccountsGlobalStateProviderKey.self] }
        set { Self[CryptoAccountsGlobalStateProviderKey.self] = newValue }
    }
}

private struct CryptoAccountsGlobalStateProviderKey: InjectionKey {
    static var currentValue: CryptoAccountsGlobalStateProvider = CommonCryptoAccountsGlobalStateProvider()
}
