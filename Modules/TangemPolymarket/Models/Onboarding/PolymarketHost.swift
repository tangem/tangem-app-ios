//
//  PolymarketHost.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PolymarketHost {
    static let polymarket = URL(string: "https://polymarket.com")!
    static let relayer = URL(string: "https://relayer-v2.polymarket.com")!
    static let clob = URL(string: "https://clob.polymarket.com")!
    static let bridge = URL(string: "https://bridge.polymarket.com")!
    static let dataAPI = URL(string: "https://data-api.polymarket.com")!
    static let marketChannel = URL(string: "wss://ws-subscriptions-clob.polymarket.com/ws/market")!
    static let sportsChannel = URL(string: "wss://sports-api.polymarket.com/ws")!
}
