//
//  CommonAddressBookEncryptionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

/// AES-256-GCM over CryptoKit. A fresh random 12-byte nonce is generated per `seal`.
struct CommonAddressBookEncryptionService: AddressBookEncrypting {
    func seal(_ plaintext: Data, using key: SymmetricKey) throws -> AddressBookSealedBox {
        let sealedBox = try AES.GCM.seal(plaintext, using: key)

        return AddressBookSealedBox(
            nonce: Data(sealedBox.nonce),
            ciphertext: sealedBox.ciphertext,
            tag: sealedBox.tag
        )
    }

    func open(_ sealedBox: AddressBookSealedBox, using key: SymmetricKey) throws -> Data {
        do {
            let nonce = try AES.GCM.Nonce(data: sealedBox.nonce)
            let box = try AES.GCM.SealedBox(nonce: nonce, ciphertext: sealedBox.ciphertext, tag: sealedBox.tag)
            return try AES.GCM.open(box, using: key)
        } catch {
            throw AddressBookCryptoError.authenticationFailed
        }
    }
}
