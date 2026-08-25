//
//  ECDSASignature+stub.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import enum CryptoKit.P256
import struct Foundation.Data

extension P256.Signing.ECDSASignature {
    static var stub: P256.Signing.ECDSASignature {
        get throws {
            try P256.Signing.ECDSASignature(rawRepresentation: Data(repeating: 0xCD, count: 64))
        }
    }
}
