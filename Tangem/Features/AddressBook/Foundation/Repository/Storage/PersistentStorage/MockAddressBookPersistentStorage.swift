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

actor MockAddressBookPersistentStorage {
    private var storage: Data

    init() {
        storage = (try? CommonAddressBookCryptographer().encode(addressBook: Self.mockAddressBook)) ?? Data()
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
    static var mockAddressBook: AddressBook {
        [
            AddressBookContact(
                id: UUID(),
                name: "Satoshi Nakamoto",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        network: BlockchainNetwork(.bitcoin(testnet: false), derivationPath: nil),
                        address: "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
                        memo: nil
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Vitalik Buterin",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        network: BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil),
                        address: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
                        memo: nil
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Exchange Wallet",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        network: BlockchainNetwork(.tron(testnet: false), derivationPath: nil),
                        address: "TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE",
                        memo: "User memo 12345"
                    ),
                ]
            ),
            AddressBookContact(
                id: UUID(),
                name: "Alice",
                icon: "",
                addresses: [
                    AddressBookAddress(
                        network: BlockchainNetwork(.bitcoin(testnet: false), derivationPath: nil),
                        address: "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
                        memo: nil
                    ),
                    AddressBookAddress(
                        network: BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil),
                        address: "0x2bDfDd3e3e3F4F33dD3df3f3F3f3F3F3F3f3F3f3",
                        memo: nil
                    ),
                ]
            ),
        ]
    }
}
#endif // DEBUG
