//
//  DecodedContact.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A contact as serialized inside the encrypted blob, before signature verification.
struct DecodedContact: Hashable, Codable {
    let id: ContactID
    let name: ContactName
    let addresses: [DecodedAddressEntry]
}
