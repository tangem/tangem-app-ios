//
//  RecoveryPublicKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RecoveryPublicKey: Equatable, Sendable {
    let keyId: String?
    let algorithm: String
    let modulus: Data
    let exponent: Data
}
