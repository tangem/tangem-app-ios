//
//  CollectiblesAccountModelsRegistry+AccountListUpdater.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemCollectibles
import TangemFoundation

extension CollectiblesAccountModelsRegistry {
    final class AccountListUpdater {
        static let persistentConfig = CryptoAccountPersistentConfig(
            derivationIdentity: CryptoAccountDerivationIdentity(
                derivationIndex: Constants.derivationIndex,
                type: .collectibles
            ),
            name: Constants.name,
            icon: AccountModel.CompositeIcon(name: .package, color: .azure)
        )

        private let addToAccountList: (CryptoAccountPersistentConfig) -> Void
        private var subscription: AnyCancellable?

        init(
            vaultStatePublisher: AnyPublisher<CollectiblesState, Never>,
            isInAccountListPublisher: AnyPublisher<Bool, Never>,
            addToAccountList: @escaping (CryptoAccountPersistentConfig) -> Void
        ) {
            self.addToAccountList = addToAccountList

            bind(vaultStatePublisher: vaultStatePublisher, isInAccountListPublisher: isInAccountListPublisher)
        }
    }
}

// MARK: - Private logic

private extension CollectiblesAccountModelsRegistry.AccountListUpdater {
    func bind(
        vaultStatePublisher: AnyPublisher<CollectiblesState, Never>,
        isInAccountListPublisher: AnyPublisher<Bool, Never>
    ) {
        subscription = vaultStatePublisher
            .map(\.isAccountVisible)
            .combineLatest(isInAccountListPublisher)
            .map { isAccountVisible, isInAccountList in isAccountVisible && !isInAccountList }
            .removeDuplicates()
            .filter { $0 }
            .withWeakCaptureOf(self)
            .sink { updater, _ in
                updater.addToAccountList(Self.persistentConfig)
            }
    }
}

// MARK: - Constants

private extension CollectiblesAccountModelsRegistry.AccountListUpdater {
    enum Constants {
        static let derivationIndex = 999_799
        static let name = "Collectibles"
    }
}
