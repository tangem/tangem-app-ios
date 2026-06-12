//
//  AddressBookSaveResponseDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Response body of `PUT /address-books/{walletId}`. The new etag is delivered in the `ETag`
/// response header.
struct AddressBookSaveResponseDTO: Decodable {
    let walletId: String
    let updatedAt: String
}
