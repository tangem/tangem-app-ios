//
//  CardMockPicker.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

enum CardMockPicker {
    enum PickerError: Error, CustomStringConvertible {
        case noCandidates(excluded: [CardMockAccessibilityIdentifiers])

        var description: String {
            switch self {
            case .noCandidates(let excluded):
                return "CardMockPicker: no candidates left after excluding \(excluded.map(\.rawValue))"
            }
        }
    }

    static let walletCards: [CardMockAccessibilityIdentifiers] = [
        .wallet, .wallet2, .shiba, .four12, .twin, .nodl, .xrpNote, .xlmBird, .s2c, .visa,
    ]

    static func random(
        from pool: [CardMockAccessibilityIdentifiers] = walletCards,
        excluding excluded: [CardMockAccessibilityIdentifiers]
    ) throws -> CardMockAccessibilityIdentifiers {
        let candidates = pool.filter { !excluded.contains($0) }
        guard let card = candidates.randomElement() else {
            throw PickerError.noCandidates(excluded: excluded)
        }
        XCTContext.runActivity(named: "Picked card \(card.rawValue)") { _ in }
        return card
    }
}
