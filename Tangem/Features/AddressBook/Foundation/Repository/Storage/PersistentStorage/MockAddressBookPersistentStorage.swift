//
//  MockAddressBookPersistentStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation
import BlockchainSdk
import TangemFoundation

actor MockAddressBookPersistentStorage {
    private var storage: Data

    init(userWalletId: UserWalletId) {
        let contacts = Self.mockContacts(for: userWalletId.stringValue)
        let addressBook = AddressBook(userWalletId: userWalletId, contacts: contacts)
        storage = (try? CommonAddressBookCryptographer().encode(addressBook: addressBook)) ?? Data()
    }
}

// MARK: - AddressBookPersistentStorage protocol conformance

extension MockAddressBookPersistentStorage: AddressBookPersistentStorage {
    func get() throws -> Data {
        storage
    }

    func save(addressBook: Data) throws {
        storage = addressBook
    }
}

// MARK: - Mock data

private extension MockAddressBookPersistentStorage {
    /// Picks one of the predefined books deterministically, so the same wallet always shows the same
    /// contacts while different wallets get visibly different books.
    static func mockContacts(for storageIdentifier: String) -> [AddressBookContact] {
        guard !mockBooks.isEmpty else { return [] }

        let stableHash = storageIdentifier.utf8.reduce(0) { $0 &+ Int($1) }
        return mockBooks[stableHash % mockBooks.count]
    }

    static let mockBooks: [[AddressBookContact]] = [
        [
            AddressBookContact(
                id: UUID(),
                name: "Satoshi Nakamoto",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
                        memo: nil,
                        networks: [BlockchainNetwork(.bitcoin(testnet: false), derivationPath: nil)]
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Vitalik Buterin",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
                        memo: nil,
                        networks: [BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)]
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Exchange Wallet",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE",
                        memo: "User memo 12345",
                        networks: [BlockchainNetwork(.tron(testnet: false), derivationPath: nil)]
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Alice",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
                        memo: nil,
                        networks: [BlockchainNetwork(.bitcoin(testnet: false), derivationPath: nil)]
                    ),
                    AddressBookAddress(
                        address: "0x2bDfDd3e3e3F4F33dD3df3f3F3f3F3F3F3f3F3f3",
                        memo: nil,
                        networks: [BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)]
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "EVM Multichain",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B",
                        memo: nil,
                        networks: [
                            BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil),
                            BlockchainNetwork(.polygon(testnet: false), derivationPath: nil),
                            BlockchainNetwork(.bsc(testnet: false), derivationPath: nil),
                        ]
                    ),
                ]
            ),
        ],
        [
            AddressBookContact(
                id: UUID(),
                name: "Bob",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "LcHK4ahcfYpYbabsXAY3F2vGz9LkN5MYg5",
                        memo: nil,
                        networks: [BlockchainNetwork(.litecoin, derivationPath: nil)]
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Charlie",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
                        memo: nil,
                        networks: [BlockchainNetwork(.solana(curve: .ed25519, testnet: false), derivationPath: nil)]
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Cold Storage",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
                        memo: nil,
                        networks: [BlockchainNetwork(.bitcoin(testnet: false), derivationPath: nil)]
                    ),
                ]
            ),
        ],
        [
            AddressBookContact(
                id: UUID(),
                name: "Dana",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
                        memo: nil,
                        networks: [BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)]
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "TRON Payouts",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        address: "TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC",
                        memo: "Payouts",
                        networks: [BlockchainNetwork(.tron(testnet: false), derivationPath: nil)]
                    ),
                ]
            ),
        ],
    ]
}
#endif // DEBUG
