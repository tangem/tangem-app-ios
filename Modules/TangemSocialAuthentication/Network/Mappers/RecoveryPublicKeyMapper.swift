//
//  RecoveryPublicKeyMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum RecoveryPublicKeyMapper {
    static func map(_ response: RecoveryPublicKeyDTO.Response) throws(RecoveryKeyEncryptionError) -> RecoveryPublicKey {
        guard
            let modulus = response.n.base64URLDecodedData(),
            let exponent = response.e.base64URLDecodedData()
        else {
            throw .invalidPublicKey
        }

        return RecoveryPublicKey(
            keyId: response.kid.isEmpty ? nil : response.kid,
            algorithm: response.alg,
            modulus: modulus,
            exponent: exponent
        )
    }
}
