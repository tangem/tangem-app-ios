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

final class CommonCryptoAccountsGlobalStateProvider {
    private let cryptoAccountsCountSubject = CurrentValueSubject<[AnyHashable: Int], Never>([:])
    private var subscriptions: [AnyHashable: AnyCancellable] = [:]

    fileprivate init() {}
}

// MARK: - CryptoAccountsGlobalStateProvider protocol conformance

extension CommonCryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider {
    func register<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        subscriptions[identifier] = manager
            .cryptoAccountModelsPublisher
            .map(\.count)
            .assign(to: \.value[identifier], on: cryptoAccountsCountSubject, ownership: .weak)
    }

    func unregister<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        subscriptions.removeValue(forKey: identifier)
        cryptoAccountsCountSubject.value.removeValue(forKey: identifier)
    }

    func globalCryptoAccountsState() -> CryptoAccounts.State {
        Self.globalState(for: cryptoAccountsCountSubject.value)
    }

    func globalCryptoAccountsStatePublisher() -> AnyPublisher<CryptoAccounts.State, Never> {
        cryptoAccountsCountSubject
            .map(Self.globalState(for:))
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private static func globalState(for cryptoAccountsCount: [AnyHashable: Int]) -> CryptoAccounts.State {
        // If we have at least one wallet with more than one crypto account, then the global state is `.multiple`
        return cryptoAccountsCount.values.contains { $0 > 1 } ? .multiple : .single
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
