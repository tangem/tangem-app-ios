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

    /// The book set for this provider's scope. The underlying wallets can't change while the address book is
    /// open, but the published array may re-emit as membership is recomputed reactively — a wallet drops out
    /// once its (network-scoped) book becomes empty. `AllWalletsAddressBooksProvider` emits a single value;
    /// the filtering providers emit again as contacts load or change.
    var addressBooksPublisher: AnyPublisher<[AddressBookWallet], Never> { get }
}
