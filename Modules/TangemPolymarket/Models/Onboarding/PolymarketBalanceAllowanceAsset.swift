//
//  PolymarketBalanceAllowanceAsset.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketBalanceAllowanceAsset: Hashable, Sendable {
    case collateral
    case conditional(tokenId: String)
    case conditionalV2(tokenId: String)

    public static func position(tokenId: String, version: PolymarketMarketVersion) -> Self? {
        switch version {
        case .v1: .conditional(tokenId: tokenId)
        case .v2: .conditionalV2(tokenId: tokenId)
        case .unknown: nil
        }
    }
}

extension PolymarketBalanceAllowanceAsset {
    var assetType: String {
        switch self {
        case .collateral: "COLLATERAL"
        case .conditional: "CONDITIONAL"
        case .conditionalV2: "CONDITIONAL-V2"
        }
    }

    var tokenId: String? {
        switch self {
        case .collateral: nil
        case .conditional(let tokenId), .conditionalV2(let tokenId): tokenId
        }
    }
}
