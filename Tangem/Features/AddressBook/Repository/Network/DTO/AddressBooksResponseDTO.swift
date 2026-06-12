//
//  AddressBooksResponseDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Response of `POST /address-books`. A wallet whose book is unchanged (matching etag) or absent is
/// simply not included in `items`.
struct AddressBooksResponseDTO: Decodable {
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
