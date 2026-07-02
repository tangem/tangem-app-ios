//
//  AllWalletsAddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// Every unlocked wallet with its full address book — used when picking a wallet to add a contact to.
final class AllWalletsAddressBooksProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
}

// MARK: - AddressBooksProvider

extension AllWalletsAddressBooksProvider: AddressBooksProvider {
    var addressBooks: [AddressBookWallet] {
        makeAddressBooks()
    }

    var addressBooksPublisher: AnyPublisher<[AddressBookWallet], Never> {
        Just(makeAddressBooks()).eraseToAnyPublisher()
    }
}

// MARK: - Helpers

private extension AllWalletsAddressBooksProvider {
    func makeAddressBooks() -> [AddressBookWallet] {
        userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .map { model in
                let manager = model.addressBookManager
                return AddressBookWallet(
                    wallet: model.userWalletInfo,
                    addressBookManager: manager,
                    addressBookPublisher: manager.contactsPublisher,
                    syncStatePublisher: manager.syncStatePublisher
                )
            }
    }
}
