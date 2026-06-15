//
//  DecodedContact.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A contact as serialized inside the encrypted blob, before signature verification. The shape
/// matches the cross-platform blob schema: a contact carries its own `walletId` and timestamps, and
/// all of these fields live inside the ciphertext (never visible to the backend).
struct DecodedContact: Hashable, Codable {
    let id: ContactID
    let walletId: String
    let name: ContactName
    let createdAt: Date
    let updatedAt: Date
    let addresses: [DecodedAddressEntry]
}
