//
//  TangemPayNetwork.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TangemPayNetwork: Int {
    case ethereum = 1
    case bsc = 56
    case polygon = 137
    case base = 8453
    case arbitrum = 42161

    var chainId: Int { rawValue }

    var displayName: String {
        switch self {
        case .ethereum: "Ethereum"
        case .bsc: "BNB Smart Chain"
        case .polygon: "Polygon"
        case .base: "Base"
        case .arbitrum: "Arbitrum One"
        }
    }
}
