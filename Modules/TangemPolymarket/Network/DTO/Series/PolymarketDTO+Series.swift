//
//  PolymarketDTO+Series.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension PolymarketDTO {
    struct Series: Decodable {
        let id: String
        let label: String
        let icon: String?
    }
}
