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
        private let isInAccountListSubject = CurrentValueSubject<Bool, Never>(false)
        private var subscription: AnyCancellable?

        init(
            vaultStatePublisher: AnyPublisher<CollectiblesState, Never>,
            canAddToAccountList: Bool,
            addToAccountList: @escaping (CryptoAccountPersistentConfig) -> Void
        ) {
            self.addToAccountList = addToAccountList

            guard canAddToAccountList else {
                return
            }

            bind(vaultStatePublisher: vaultStatePublisher)
        }

        func update(isInAccountList: Bool) {
            isInAccountListSubject.send(isInAccountList)
        }
    }
}

// MARK: - Private logic

private extension CollectiblesAccountModelsRegistry.AccountListUpdater {
    func bind(vaultStatePublisher: AnyPublisher<CollectiblesState, Never>) {
        subscription = vaultStatePublisher
            .map(\.isAccountVisible)
            .combineLatest(isInAccountListSubject)
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
