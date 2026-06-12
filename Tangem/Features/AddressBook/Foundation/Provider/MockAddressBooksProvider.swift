//
//  MockAddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Temporary provider that exposes the real wallets (names) from the repository with mocked, static
/// contacts. Will be replaced once the address book Foundation layer lands ([REDACTED_INFO]).
final class MockAddressBooksProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
}

// MARK: - AddressBooksProvider

extension MockAddressBooksProvider: AddressBooksProvider {
    var addressBooks: [AddressBookWallet] {
        userWalletRepository.models
            .filter { !$0.isUserWalletLocked }
            .map { userWalletModel in
                let contacts = Self.mockContacts(for: userWalletModel.userWalletId.stringValue)
                let addressBook = AddressBook(userWalletId: userWalletModel.userWalletId, contacts: contacts)

                return AddressBookWallet(
                    wallet: userWalletModel.userWalletInfo,
                    addressBookPublisher: Just(addressBook).eraseToAnyPublisher()
                )
            }
    }
}

// MARK: - Mock data

private extension MockAddressBooksProvider {
    /// Picks one of the predefined books deterministically, so the same wallet always shows the same
    /// contacts while different wallets get visibly different books.
    static func mockContacts(for storageIdentifier: String) -> [AddressBookContact] {
        guard !mockBooks.isEmpty else { return [] }

        let stableHash = storageIdentifier.utf8.reduce(0) { $0 &+ Int($1) }
        return mockBooks[stableHash % mockBooks.count]
    }

    static func address(_ networkId: String, _ address: String, memo: String? = nil) -> AddressBookAddress {
        AddressBookAddress(id: UUID(), networkId: networkId, address: address, memo: memo, signature: "")
    }

    static let mockBooks: [[AddressBookContact]] = [
        [
            AddressBookContact(
                id: UUID(),
                name: "Satoshi Nakamoto",
                icon: "",
                addresses: [address("bitcoin", "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Vitalik Buterin",
                icon: "",
                addresses: [address("ethereum", "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Exchange Wallet",
                icon: "",
                addresses: [address("tron", "TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE", memo: "User memo 12345")]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Alice",
                icon: "",
                addresses: [
                    address("bitcoin", "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq"),
                    address("ethereum", "0x2bDfDd3e3e3F4F33dD3df3f3F3f3F3F3F3f3F3f3"),
                ]
            ),
        ],
        [
            AddressBookContact(
                id: UUID(),
                name: "Bob",
                icon: "",
                addresses: [address("litecoin", "LcHK4ahcfYpYbabsXAY3F2vGz9LkN5MYg5")]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Charlie",
                icon: "",
                addresses: [address("solana", "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM")]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Cold Storage",
                icon: "",
                addresses: [address("bitcoin", "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh")]
            ),
        ],
    ]
}
