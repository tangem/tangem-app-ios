//
//  NonEmptyAddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

/// Only wallets whose address book has contacts — used from the wallet settings, where empty books
/// aren't listed. Emptiness is decided reactively, so a wallet appears as its contacts load.
final class NonEmptyAddressBooksProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
}

// MARK: - AddressBooksProvider

extension NonEmptyAddressBooksProvider: AddressBooksProvider {
    var addressBooks: [AddressBookWallet] {
        makeAddressBooks().filter { $0.addressBookManager.contacts.isNotEmpty }
    }

    var addressBooksPublisher: AnyPublisher<[AddressBookWallet], Never> {
        // Empty books can't be dropped synchronously — contacts load asynchronously — so decide reactively.
        Just(makeAddressBooks())
            .flatMapLatest { addressBooks -> AnyPublisher<[AddressBookWallet], Never> in
                guard addressBooks.isNotEmpty else {
                    return .just(output: [])
                }

                return addressBooks
                    .map { addressBook in
                        addressBook.addressBookPublisher
                            .map { $0.isNotEmpty ? addressBook : nil }
                            .eraseToAnyPublisher()
                    }
                    .combineLatest()
                    .map { $0.compactMap { $0 } }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

private extension NonEmptyAddressBooksProvider {
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
