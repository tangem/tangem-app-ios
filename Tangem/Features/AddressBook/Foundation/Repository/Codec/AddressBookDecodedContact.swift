//
//  AddressBookDecodedContact.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A contact as serialized inside the encrypted blob, before signature verification. The shape
/// matches the cross-platform blob schema: a contact carries its own `walletId` and timestamps, and
/// all of these fields live inside the ciphertext (never visible to the backend).
struct AddressBookDecodedContact: Hashable, Codable {
    let id: AddressBookContactID
    let walletId: String
    let name: AddressBookContactName
    /// Optional custom icon. Left empty for the first iteration (the avatar is derived from `name`).
    let icon: String
    /// Avatar background color as the bare color id (e.g. "MexicanPink"), per the cross-platform blob schema.
    let iconColor: String
    let createdAt: Date
    let updatedAt: Date
    let addresses: [AddressBookDecodedAddressEntry]
}
