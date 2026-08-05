//
//  PolymarketDTO+SeriesResponse.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketDTO {
    struct SeriesResponse: Decodable {
        let series: [Series]
    }
}
