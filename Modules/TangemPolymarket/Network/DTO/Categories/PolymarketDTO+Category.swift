//
//  PolymarketDTO+Category.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketDTO {
    struct Category: Decodable {
        let id: Int
        let label: String
        let icon: String?
    }
}
