//
//  AddressBookDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum AddressBookDTO {}

extension AddressBookDTO {
    /// Shape of the encrypted envelope as persisted in the local cache. All binary fields are hex strings.
    /// `salt` is intentionally omitted: the encryption key is derived deterministically from the wallet key,
    /// so no salt is needed.
    struct Envelope: Codable {
        let version: String
        let walletId: String
        let updatedAt: String
        let nonce: String
        let ciphertext: String
        let authTag: String
    }
}

extension AddressBookDTO {
    struct SyncRequest: Encodable {
        let wallets: [Wallet]

        struct Wallet: Encodable {
            let walletId: String
            let etag: String?
        }
    }
}

extension AddressBookDTO {
    struct UpdateRequest: Encodable {
        let version: String
        let nonce: String
        let ciphertext: String
        let authTag: String
    }
}

extension AddressBookDTO {
    struct UpdateResponse: Decodable {
        let walletId: String
        let updatedAt: String
        let etag: String
    }
}

extension AddressBookDTO {
    struct Response: Decodable {
        let items: [Item]

        struct Item: Decodable {
            let walletId: String
            let etag: String
            let version: String
            let updatedAt: String
            let nonce: String
            let ciphertext: String
            let authTag: String
        }
    }
}
