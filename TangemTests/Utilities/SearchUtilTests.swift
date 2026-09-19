//
//  SearchUtilTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class SearchUtilTests: XCTestCase {
    private struct Item: Equatable {
        let name: String
    }

    private let countries: [Item] = [
        "Australia", "Austria", "Belgium", "Bulgaria", "Cuba", "Ecuador", "Guatemala", "Hungary",
        "Lithuania", "Luxembourg", "Mauritius", "Peru", "Portugal", "Russia", "Saudi Arabia",
        "South Africa", "Turkey", "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom",
        "United States", "Uruguay", "Uzbekistan",
    ].map(Item.init)

    func testEmptySearchTextReturnsAllItemsUnchanged() {
        let result = SearchUtil.search(countries, in: \.name, for: "")

        XCTAssertEqual(result, countries)
    }

    func testNoMatchesReturnsEmptyResult() {
        let result = SearchUtil.search(countries, in: \.name, for: "xyz")

        XCTAssertTrue(result.isEmpty)
    }

    func testFilterIsCaseInsensitive() {
        let result = SearchUtil.search(countries, in: \.name, for: "PERU")

        XCTAssertEqual(result, [Item(name: "Peru")])
    }

    func testSearchTextIsTrimmedBeforeMatching() {
        let result = SearchUtil.search(countries, in: \.name, for: "  peru ")

        XCTAssertEqual(result, [Item(name: "Peru")])
    }

    func testWordPrefixMatchesKeepOriginalOrder() {
        // Small (< 20 elements) input: previously handled by the stdlib insertion sort,
        // which reversed every prefix match because of the one-sided comparator.
        let items = Array(countries.suffix(10))

        let result = SearchUtil.search(items, in: \.name, for: "u")

        XCTAssertEqual(
            result.map(\.name),
            [
                "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan",
                "Saudi Arabia", "South Africa", "Turkey",
            ]
        )
    }

    func testWordPrefixMatchesKeepOriginalOrderForLargeInput() {
        // > 20 elements: previously handled by the stdlib merge sort path.
        let result = SearchUtil.search(countries, in: \.name, for: "u")

        XCTAssertEqual(
            result.map(\.name),
            [
                "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan",
                "Australia", "Austria", "Belgium", "Bulgaria", "Cuba", "Ecuador", "Guatemala", "Hungary",
                "Lithuania", "Luxembourg", "Mauritius", "Peru", "Portugal", "Russia", "Saudi Arabia",
                "South Africa", "Turkey",
            ]
        )
    }

    func testWordPrefixMatchesComeBeforeSubstringMatches() {
        let result = SearchUtil.search(countries, in: \.name, for: "un")

        XCTAssertEqual(
            result.map(\.name),
            ["United Arab Emirates", "United Kingdom", "United States", "Hungary"]
        )
    }

    func testPrefixOfNonLeadingWordIsTreatedAsWordPrefixMatch() {
        let items: [Item] = ["Papua New Guinea", "Argentina", "Guinea", "New Zealand"].map(Item.init)

        let result = SearchUtil.search(items, in: \.name, for: "gui")

        XCTAssertEqual(result.map(\.name), ["Papua New Guinea", "Guinea"])
    }

    func testDuplicateValuesKeepOriginalOrder() {
        struct Tagged: Equatable {
            let name: String
            let tag: Int
        }

        let items = (0 ..< 25).map { Tagged(name: "Same Name", tag: $0) }

        let result = SearchUtil.search(items, in: \.name, for: "same")

        XCTAssertEqual(result, items)
    }
}
