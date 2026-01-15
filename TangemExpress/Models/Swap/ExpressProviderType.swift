//
//  ExpressProviderType.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressProviderType: String, Hashable, Decodable, CaseIterable {
    case dex
    case cex
    case dexBridge = "dex-bridge"
    case onramp
    /// For possible future types
    case unknown

    public var title: String {
        switch self {
        case .dex, .cex, .onramp:
            return rawValue.uppercased()
        case .unknown:
            return "unknown"
        case .dexBridge:
            return "DEX/Bridge"
        }
    }
}
