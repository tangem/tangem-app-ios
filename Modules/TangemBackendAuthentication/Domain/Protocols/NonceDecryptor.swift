//
//  NonceDecryptor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

protocol NonceDecryptor: Sendable {
    func decrypt(cipheredNonce: String) throws(NonceDecryptorError) -> Data
}
