//
//  EarnYieldPickerSectionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics
import Testing
@testable import Tangem

@Suite("EarnYieldPickerSection")
struct EarnYieldPickerSectionTests {
    @Test(
        "The current section is the last one past a line that slides from the pinned tabs to the screen bottom over the last screen of scrolling",
        arguments: [
            (Tops(calculator: 600, benefits: 1200, details: 1400), 2000, EarnYieldPickerSection.calculator),
            (Tops(calculator: 100, benefits: 700, details: 900), 2000, .calculator),
            (Tops(calculator: -500, benefits: 100, details: 300), 2000, .benefits),
            (Tops(calculator: -500, benefits: 300, details: 600), 300, .benefits),
            (Tops(calculator: -500, benefits: 300, details: 500), 0, .details),
            (Tops(calculator: -500, benefits: nil, details: 300), 2000, .calculator),
        ]
    )
    func current(tops: Tops, remainingScroll: CGFloat, expected: EarnYieldPickerSection) {
        let current = EarnYieldPickerSection.current(
            sectionTops: tops.bySection,
            pinnedEdge: 100,
            visibleBottom: 800,
            remainingScroll: remainingScroll
        )

        #expect(current == expected)
    }
}

// MARK: - Helpers

extension EarnYieldPickerSectionTests {
    struct Tops: CustomTestStringConvertible {
        let calculator: CGFloat
        let benefits: CGFloat?
        let details: CGFloat

        var bySection: [EarnYieldPickerSection: CGFloat] {
            var tops: [EarnYieldPickerSection: CGFloat] = [.calculator: calculator, .details: details]
            tops[.benefits] = benefits
            return tops
        }

        var testDescription: String {
            "\(calculator)/\(benefits.map { "\($0)" } ?? "none")/\(details)"
        }
    }
}
