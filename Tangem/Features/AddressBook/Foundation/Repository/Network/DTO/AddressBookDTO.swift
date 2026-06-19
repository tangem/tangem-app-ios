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
    /// `salt` from the original spec is intentionally omitted: the encryption key is derived
    /// deterministically from the wallet key, so no salt is needed. The wire request uses `UpdateRequest`
    /// and the wire response `Response.Item`; this type is the durable on-device mirror.
    struct Envelope: Codable {
        let version: String
        let walletId: String
        let updatedAt: String
        let nonce: String
        let ciphertext: String
        let authTag: String

        enum CodingKeys: String, CodingKey {
            case version
            case walletId
            case updatedAt
            case nonce
            case ciphertext
            case authTag = "auth_tag"
        }
    }
}

extension AddressBookDTO {
    /// Body of `POST /address-books/sync` (spec §3.9): the wallets to sync, each with its known `etag`
    /// (omitted for a wallet with no local cache yet) so the backend can skip unchanged books.
    struct SyncRequest: Encodable {
        let wallets: [Wallet]

        struct Wallet: Encodable {
            let walletId: String
            let etag: String?
        }
    }
}

extension AddressBookDTO {
    /// Body of `PUT /address-books/{walletId}` (spec §4): the encrypted blob without `walletId` (it is in
    /// the path). The new etag comes back in the `UpdateResponse` body.
    struct UpdateRequest: Encodable {
        let version: String
        let nonce: String
        let ciphertext: String
        let authTag: String
    }
}

extension AddressBookDTO {
    /// Response body of `PUT /address-books/{walletId}`: the new etag (used as the next `If-Match`) plus
    /// the server timestamp.
    struct UpdateResponse: Decodable {
        let walletId: String
        let updatedAt: String
        let etag: String
    }
}

extension AddressBookDTO {
    /// Response of `POST /address-books/sync`. A wallet whose book is unchanged (matching etag) or absent
    /// is simply not included in `items`.
    struct Response: Decodable {
        let items: [Item]

        struct Item: Decodable {
            let walletId: String
            let etag: String
            let updatedAt: String
            let nonce: String
            let ciphertext: String
            let authTag: String
        }
    }
}
