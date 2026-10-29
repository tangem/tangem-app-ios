//
//  AppAttestation.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

struct AppAttestation: Equatable, Sendable {
    let keyID: String
    let object: Data
}
