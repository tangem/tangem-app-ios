//
//  PolymarketCategoryMappingTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket category mapping", .timeLimit(.minutes(1)))
struct PolymarketCategoryMappingTests {
    private let mapper = PolymarketMapper()

    @Test("A category from a backend without subcategories and filters decodes as a plain category")
    func missingFieldsDecodeAsEmpty() throws {
        let category = try mapped(#"{"id": 7, "label": "Politics", "icon": "politics"}"#)

        #expect(category.subcategories.isEmpty)
        #expect(category.filters.isEmpty)
    }

    @Test("Subcategories keep their order, labels, icons and filters")
    func subcategoriesAreMapped() throws {
        let category = try mapped(#"""
        {
            "id": 1, "label": "Sports", "icon": "sports", "filters": ["games", "props"], "hasSeries": false,
            "subcategories": [
                {"id": 10, "label": "Soccer", "icon": "soccer", "filters": ["games"], "hasSeries": true},
                {"id": 11, "label": "NBA", "icon": "nba"}
            ]
        }
        """#)

        #expect(category.filters == [.games, .props])
        #expect(category.subcategories.map(\.id) == [10, 11])
        #expect(category.subcategories.map(\.label) == ["Soccer", "NBA"])
        #expect(category.subcategories.map(\.icon) == [.soccer, .nba])
        #expect(category.subcategories[0].filters == [.games])
        #expect(category.subcategories[1].filters.isEmpty)
    }

    @Test("A subcategory pointing back at its parent and a repeated subcategory are dropped")
    func selfAndRepeatedSubcategoriesAreDropped() throws {
        let category = try mapped(#"""
        {
            "id": 1, "label": "Sports", "icon": "sports",
            "subcategories": [
                {"id": 1, "label": "Sports", "icon": "sports", "filters": ["games"], "hasSeries": false},
                {"id": 10, "label": "Soccer"},
                {"id": 10, "label": "Soccer again"}
            ]
        }
        """#)

        #expect(category.subcategories.map(\.id) == [10])
        #expect(category.subcategories.map(\.label) == ["Soccer"])
    }

    @Test("A category whose only subcategory is itself has no subcategories")
    func selfOnlySubcategoryLeavesNoSubcategories() throws {
        let category = try mapped(#"""
        {"filters": ["games"], "hasSeries": false, "icon": "sports", "id": 1, "label": "Sports",
         "subcategories": [{"filters": ["games"], "hasSeries": false, "icon": "sports", "id": 1, "label": "Sports"}]}
        """#)

        #expect(category.subcategories.isEmpty)
        #expect(category.filters == [.games])
    }

    @Test("A filter this build does not know is kept as unknown instead of failing the list")
    func unknownFilterIsKept() throws {
        let category = try mapped(#"{"id": 1, "label": "Sports", "filters": ["games", "outrights"]}"#)

        #expect(category.filters == [.games, .unknown("outrights")])
    }
}

// MARK: - Helpers

private extension PolymarketCategoryMappingTests {
    func mapped(_ json: String) throws -> PolymarketCategory {
        try mapper.mapCategory(JSONDecoder().decode(PolymarketDTO.Category.self, from: Data(json.utf8)))
    }
}
