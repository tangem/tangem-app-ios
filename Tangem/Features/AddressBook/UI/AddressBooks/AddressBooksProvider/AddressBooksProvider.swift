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

    /// The current book set. The set of wallets can't change while the address book is open, so this emits
    /// once; per-book contact changes come from `AddressBookWallet`, not from here.
    var addressBooksPublisher: AnyPublisher<[AddressBookWallet], Never> { get }
}
