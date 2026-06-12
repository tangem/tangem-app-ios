//
//  AddressBookEnvelopeDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Wire shape of the encrypted envelope — the body of `PUT /address-books/{walletId}`. All binary
/// fields are hex strings. `salt` from the original spec is intentionally omitted: the encryption key
/// is derived deterministically from the wallet key, so no salt is needed.
struct AddressBookEnvelopeDTO: Codable {
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
