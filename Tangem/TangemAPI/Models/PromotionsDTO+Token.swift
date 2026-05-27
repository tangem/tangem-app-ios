//
//  PromotionsDTO+Token.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Token Details / Yield Support

extension PromotionsDTO.Load {
    struct TokenInfo: Decodable {
        let networkId: String
        let token: Token
    }

    struct Token: Decodable {
        let id: String
        let symbol: String
        let name: String
        let address: String
        let decimalCount: Int
    }
}
