//
//  PolymarketDTO+Outcome.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct Outcome: Decodable {
        let assetId: String
        let label: String
        let probability: Decimal?
    }
}
