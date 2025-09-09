//
//  WCTransactionsFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct ReownWalletKit.Request

final actor WCTransactionsFilter {
    private var recent: [Request: Date] = [:]
    private let window: TimeInterval

    init(window: TimeInterval = 120) {
        self.window = window
    }

    func filter(_ request: Request) -> Bool {
        let now = Date()

        recent = recent.filter { now.timeIntervalSince($0.value) < window }

        if let ts = recent[request], now.timeIntervalSince(ts) < window {
            return false
        }
        
        recent[request] = now
        return true
    }
}

extension Request: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(method)
        hasher.combine(topic)
        hasher.combine(params)
        hasher.combine(chainId)
        hasher.combine(expiryTimestamp)
    }
}
