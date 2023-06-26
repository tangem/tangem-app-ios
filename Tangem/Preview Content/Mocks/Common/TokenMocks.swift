//
//  TokenMocks.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Token {
    static var tetherMock: Token {
        Token(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
            decimalCount: 6,
            id: "tether"
        )
    }

    static var sushiMock: Token {
        Token(
            name: "Sushi",
            symbol: "SUSHI",
            contractAddress: "0x0b3f868e0be5597d5db7feb59e1cadbb0fdda50a",
            decimalCount: 18,
            id: "sushi"
        )
    }

    static var inverseBTCBlaBlaBlaMock: Token {
        Token(
            name: "Inverse BTC Flexible Leverage Index",
            symbol: "IBTC-FLI-P",
            contractAddress: "0x130ce4e4f76c2265f94a961d70618562de0bb8d2",
            decimalCount: 18,
            id: "inverse-btc-flexible-leverage-index"
        )
    }
}
