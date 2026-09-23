//
//  FeedDeeplinkTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Discover link parameters")
struct FeedDeeplinkTests {
    @Test("A link without parameters opens the default section")
    func emptyLink() {
        #expect(makeSelection() == .crypto(categoryId: nil))
    }

    @Test("An unknown section falls back to the default one")
    func unknownSection() {
        #expect(makeSelection(section: "bonds") == .crypto(categoryId: nil))
    }

    @Test("The category travels with its section", arguments: [
        ("crypto", FeedSelection.crypto(categoryId: "layer-1")),
        ("assets", FeedSelection.realAssets(categoryId: "layer-1")),
    ])
    func categorySections(section: String, expected: FeedSelection) {
        #expect(makeSelection(section: section, category: "layer-1") == expected)
    }

    @Test("An empty category is the same as none at all")
    func emptyCategory() {
        #expect(makeSelection(section: "assets", category: "") == .realAssets(categoryId: nil))
    }

    @Test("Earn takes the type instead of a category")
    func earnType() {
        #expect(makeSelection(section: "earn", category: "xstocks", type: "staking") == .earn(type: .staking))
    }

    @Test("A type the app has no filter for leaves Earn unfiltered")
    func unsupportedEarnType() {
        #expect(makeSelection(section: "earn", type: "embedded_yield") == .earn(type: nil))
    }

    @Test("The type is ignored outside Earn")
    func typeOutsideEarn() {
        #expect(makeSelection(section: "assets", type: "staking") == .realAssets(categoryId: nil))
    }
}

// MARK: - Helpers

private extension FeedDeeplinkTests {
    func makeSelection(section: String? = nil, category: String? = nil, type: String? = nil) -> FeedSelection {
        FeedDeeplink(section: section, category: category, type: type).makeSelection()
    }
}
