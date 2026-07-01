//
//  CardMockPicker.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers

enum CardMockPicker {
    static let walletCards: [CardMockAccessibilityIdentifiers] = [
        .wallet, .wallet2, .shiba, .four12, .twin, .nodl, .xrpNote, .xlmBird, .s2c, .visa,
    ]

    static func random(
        from pool: [CardMockAccessibilityIdentifiers] = walletCards,
        excluding excluded: [CardMockAccessibilityIdentifiers]
    ) -> CardMockAccessibilityIdentifiers {
        let candidates = pool.filter { !excluded.contains($0) }
        guard let card = candidates.randomElement() else {
            fatalError("No card left after excluding \(excluded) from \(pool)")
        }
        return card
    }
}
