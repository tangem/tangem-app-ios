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
    /// Wire shape of the encrypted envelope — the body of `PUT /address-books/{walletId}`. All binary
    /// fields are hex strings. `salt` from the original spec is intentionally omitted: the encryption key
    /// is derived deterministically from the wallet key, so no salt is needed. Field names and format are
    /// to be confirmed against the backend spec during the real network integration (T4).
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
    /// Body of `POST /address-books` — loads the books for several wallets at once. Passing the known
    /// `etags` lets the backend omit unchanged books from the response.
    struct Request: Encodable {
        let walletIds: [String]
        let etags: [String: String]?
    }
}

extension AddressBookDTO {
    /// Response of `POST /address-books`. A wallet whose book is unchanged (matching etag) or absent is
    /// simply not included in `items`.
    struct Response: Decodable {
        let items: [Item]

        struct Item: Decodable {
            let walletId: String
            let etag: String
            let updatedAt: String
            let nonce: String
            let ciphertext: String
            let authTag: String

            enum CodingKeys: String, CodingKey {
                case walletId
                case etag
                case updatedAt
                case nonce
                case ciphertext
                case authTag = "auth_tag"
            }
        }
    }
}

extension AddressBookDTO {
    /// Response body of `PUT /address-books/{walletId}`. The new etag is delivered in the `ETag`
    /// response header.
    struct SaveResponse: Decodable {
        let walletId: String
        let updatedAt: String
    }
}
