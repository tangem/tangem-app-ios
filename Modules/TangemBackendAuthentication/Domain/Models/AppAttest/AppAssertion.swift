//
//  AppAssertion.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

/// Demonstration of the legitimacy that Tangem app is running on a real apple device.
struct AppAssertion: Equatable, Sendable {
    let keyID: String
    let object: Data
}
