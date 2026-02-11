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

    fileprivate init() {
        cryptoAccountsGlobalStateProviderLogger.debug(
            "Instance initialized (\(objectDescription(self)))"
        )
    }
}

// MARK: - CryptoAccountsGlobalStateProvider protocol conformance

extension CommonCryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider {
    func register<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        cryptoAccountsGlobalStateProviderLogger.debug(
            "Called with \(LoggingWrapper(identifier)) (\(objectDescription(self)))"
        )

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
        cryptoAccountsGlobalStateProviderLogger.debug(
            "Called with \(LoggingWrapper(identifier)) (\(objectDescription(self)))"
        )

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
        cryptoAccountsGlobalStateProviderLogger.debug(
            "Called with \(cryptoAccountsCount.map { (LoggingWrapper($0.key), $0.value) }) (\(objectDescription(self)))"
        )

        // If we have at least one wallet with more than one crypto account, then the global state is `.multiple`
        return cryptoAccountsCount.values.contains { $0 > 1 } ? .multiple : .single
    }

    private func onCryptoAccountsCountChanged<T>(identifier: T, count: Int) where T: Hashable {
        let hasChanges = criticalSection {
            let oldValue = unsafeCryptoAccountsCount[identifier]
            unsafeCryptoAccountsCount[identifier] = count

            return oldValue != count
        }

        cryptoAccountsGlobalStateProviderLogger.debug(
            "Called with \(LoggingWrapper(identifier)), \(count), \(hasChanges) (\(objectDescription(self)))"
        )

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

// MARK: - Convenience extensions

@available(iOS, deprecated: 100000.0, message: "Temporary entity for troubleshooting, will be deleted ([REDACTED_INFO])")
private extension CommonCryptoAccountsGlobalStateProvider {
    /// We don't want to add `CustomStringConvertible` conformance to the `UserWalletId` type, as this could break
    /// some code that already depends on the default `description` implementation for this type.
    /// Also, we want to avoid using `String.StringInterpolation` because it could lead to the same results as above,
    /// but would be even harder to find and fix due to private extension.
    struct LoggingWrapper: CustomStringConvertible {
        let wrapped: AnyHashable

        init(_ wrapped: AnyHashable) {
            self.wrapped = wrapped
        }

        var description: String {
            if let userWalletId = wrapped.base as? UserWalletId {
                return userWalletId.stringValue
            }

            return String(describing: wrapped)
        }
    }
}
