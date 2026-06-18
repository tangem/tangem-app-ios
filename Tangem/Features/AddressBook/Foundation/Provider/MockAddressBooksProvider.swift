//
//  MockAddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

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
                let contacts = Self.mockContacts(for: userWalletModel.userWalletId)
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
    static func mockContacts(for userWalletId: UserWalletId) -> [AddressBookContact] {
        let books = mockBooks(userWalletId: userWalletId)
        guard !books.isEmpty else { return [] }

        let stableHash = userWalletId.stringValue.utf8.reduce(0) { $0 &+ Int($1) }
        return books[stableHash % books.count]
    }

    static func contact(
        _ name: String,
        color: AccountModel.CompositeIcon.Color,
        userWalletId: UserWalletId,
        addresses: [AddressBookAddress]
    ) -> AddressBookContact {
        AddressBookContact(id: UUID(), name: name, icon: "", color: color, userWalletId: userWalletId, addresses: addresses)
    }

    static func address(_ networkId: String, _ address: String, memo: String? = nil) -> AddressBookAddress {
        AddressBookAddress(id: UUID(), networkId: networkId, address: address, memo: memo, signature: "")
    }

    static func mockBooks(userWalletId: UserWalletId) -> [[AddressBookContact]] {
        [
            [
                contact("Satoshi Nakamoto", color: .azure, userWalletId: userWalletId, addresses: [
                    address("bitcoin", "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"),
                ]),
                contact("Vitalik Buterin", color: .vitalGreen, userWalletId: userWalletId, addresses: [
                    address("ethereum", "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"),
                ]),
                contact("Exchange Wallet", color: .mexicanPink, userWalletId: userWalletId, addresses: [
                    address("tron", "TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE", memo: "User memo 12345"),
                ]),
                contact("Alice", color: .caribbeanBlue, userWalletId: userWalletId, addresses: [
                    address("bitcoin", "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq"),
                    address("ethereum", "0x2bDfDd3e3e3F4F33dD3df3f3F3f3F3F3F3f3F3f3"),
                ]),
            ],
            [
                contact("Bob", color: .palatinateBlue, userWalletId: userWalletId, addresses: [
                    address("litecoin", "LcHK4ahcfYpYbabsXAY3F2vGz9LkN5MYg5"),
                ]),
                contact("Charlie", color: .ufoGreen, userWalletId: userWalletId, addresses: [
                    address("solana", "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"),
                ]),
                contact("Cold Storage", color: .fuchsiaNebula, userWalletId: userWalletId, addresses: [
                    address("bitcoin", "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"),
                ]),
            ],
        ]
    }
}
