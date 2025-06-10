//
//  ExpressProviderType.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressProviderType: String, Hashable, Decodable {
    case dex
    case cex
    case dexBridge = "dex-bridge"
    case onramp
    /// For possible future types
    case unknown
}
