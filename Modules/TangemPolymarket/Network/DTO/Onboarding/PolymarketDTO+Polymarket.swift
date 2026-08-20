//
//  PolymarketDTO+Polymarket.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct GeoblockResponse: Decodable {
        let blocked: Bool
        let country: String?
        let region: String?
    }

    struct NonceResponse: Decodable {
        let nonce: String
    }
}
