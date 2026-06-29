//
//  CommonAddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

/// Real provider backed by the per-wallet `AddressBookManager`. Vends each unlocked wallet's verified
/// `AddressBookContact` stream; loading is owned by the manager (it loads once on creation).
final class CommonAddressBooksProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
}

// MARK: - AddressBooksProvider

extension CommonAddressBooksProvider: AddressBooksProvider {
    var addressBooks: [AddressBookWallet] {
        Self.makeAddressBooks(from: userWalletRepository.models)
    }

    var addressBooksPublisher: AnyPublisher<[AddressBookWallet], Never> {
        let repository = userWalletRepository
        let updates = repository.eventProvider
            .filter { Self.affectsBookSet($0) }
            .map { _ in Self.makeAddressBooks(from: repository.models) }

        return Just(Self.makeAddressBooks(from: repository.models))
            .merge(with: updates)
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

private extension CommonAddressBooksProvider {
    static func makeAddressBooks(from models: [UserWalletModel]) -> [AddressBookWallet] {
        models
            .filter { !$0.isUserWalletLocked }
            .map { model in
                AddressBookWallet(
                    wallet: model.userWalletInfo,
                    addressBookManager: model.addressBookManager
                )
            }
    }

    /// Re-vend the set only when wallets appear, disappear, or change lock state — `selected`/`reordered`
    /// leave the set of books intact. Mirrors `CommonWalletModelsAggregator`'s repository-event filter.
    static func affectsBookSet(_ event: UserWalletRepositoryEvent) -> Bool {
        switch event {
        case .locked, .unlocked, .inserted, .unlockedWallet, .deleted: true
        case .selected, .reordered: false
        }
    }
}

// MARK: - Factory

extension AddressBooksProvider where Self == CommonAddressBooksProvider {
    static func common() -> Self { .init() }
}
