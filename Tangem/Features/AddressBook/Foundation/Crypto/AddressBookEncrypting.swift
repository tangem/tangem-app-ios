//
//  AddressBookEncrypting.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

/// Encrypts and decrypts the address-book plaintext with AES-256-GCM.
protocol AddressBookEncrypting {
    func seal(_ plaintext: Data, using key: SymmetricKey) throws -> AddressBookSealedBox
    func open(_ sealedBox: AddressBookSealedBox, using key: SymmetricKey) throws -> Data
}
