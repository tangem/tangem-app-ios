//
//  AddressBookSealedBox.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// AES-256-GCM output split into the fields the backend envelope carries.
struct AddressBookSealedBox: Hashable {
    /// 12-byte GCM nonce.
    let nonce: Data
    let ciphertext: Data
    /// 16-byte GCM authentication tag.
    let tag: Data
}
