//
//  PolymarketDTO+Price.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct PriceResponse: Decodable {
        let price: String?
    }
}
