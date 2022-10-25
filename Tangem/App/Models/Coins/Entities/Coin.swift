//
//  Coin.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension CoinsResponse {
    struct Coin: Codable {
        public let id: String
        public let name: String
        public let symbol: String
        public let networks: [CoinsResponse.Network]
        public let isExchangeable: Bool
    }
}
