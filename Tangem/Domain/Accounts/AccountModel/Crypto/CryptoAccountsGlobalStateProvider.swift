//
//  CryptoAccountsGlobalStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class CryptoAccountsGlobalStateProvider {
    static let shared = CryptoAccountsGlobalStateProvider()

    var statePublisher: some Publisher<CryptoAccounts.State, Never> {
        return cryptoAccountsStatesSubject
            .map { $0.values.reduceToGlobalState() }
            .removeDuplicates()
    }

    private let cryptoAccountsStatesSubject = CurrentValueSubject<[AnyHashable: CryptoAccounts.State], Never>(Constants.initialValue)
    private var subscriptions: [AnyHashable: AnyCancellable] = [:]

    private init() {}

    func register<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        subscriptions[identifier] = manager
            .accountModelsPublisher
            .map { accountModels in
                // Extracting only crypto accounts states
                return accountModels.map { accountModel in
                    switch accountModel {
                    case .standard(let cryptoAccounts):
                        return cryptoAccounts.state
                    }
                }
            }
            .map { $0.reduceToGlobalState() }
            .assign(to: \.value[identifier], on: cryptoAccountsStatesSubject, ownership: .weak)
    }

    func unregister<T, U>(_ manager: T, forIdentifier identifier: U) where T: AccountModelsManager, U: Hashable {
        subscriptions.removeValue(forKey: identifier)
        cryptoAccountsStatesSubject.value.removeValue(forKey: identifier)
    }
}

// MARK: - Convenience extensions

private extension Sequence where Element == CryptoAccounts.State {
    func reduceToGlobalState() -> CryptoAccounts.State {
        // If we have at least one `.multiple` state, then the overall state is `.multiple`
        return contains(.multiple) ? .multiple : .single
    }
}

// MARK: - Constants

private extension CryptoAccountsGlobalStateProvider {
    enum Constants {
        static let initialValue: [AnyHashable: CryptoAccounts.State] = [UUID(): .single]
    }
}
