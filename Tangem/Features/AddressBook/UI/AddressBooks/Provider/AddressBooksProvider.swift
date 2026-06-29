//
//  AddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol AddressBooksProvider {
    /// Point-in-time read for callers that act immediately (wallet picker, resolving a contact's source book).
    var addressBooks: [AddressBookWallet] { get }

    /// Pushes the book set when it changes (a wallet added / removed / locked), seeded with the current value.
    /// Per-book contact changes come from `AddressBookWallet`, not from here.
    var addressBooksPublisher: AnyPublisher<[AddressBookWallet], Never> { get }
}

struct AddressBookWallet {
    let wallet: UserWalletInfo
    let addressBookManager: AddressBookManager

    var addressBookPublisher: AnyPublisher<[AddressBookContact], Never> {
        addressBookManager.contactsPublisher
    }

    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> {
        addressBookManager.syncStatePublisher
    }
}
