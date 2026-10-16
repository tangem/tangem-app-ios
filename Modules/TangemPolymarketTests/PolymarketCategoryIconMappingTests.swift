//
//  PolymarketCategoryIconMappingTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket category icon")
struct PolymarketCategoryIconMappingTests {
    private let mapper = PolymarketMapper()

    @Test("Every key the backend can send maps to its icon", arguments: PolymarketCategoryIcon.allCases)
    func knownKeyMapsToItsIcon(icon: PolymarketCategoryIcon) throws {
        let category = try mapper.mapCategory(Self.decode(icon: "\"\(icon.rawValue)\""))

        #expect(category.icon == icon)
    }

    @Test("A key this build does not know, or no key at all, leaves the category without an icon", arguments: [
        "\"astrology\"",
        "\"Politics\"",
        "\"https://cdn.example.com/icons/politics.svg\"",
        "null",
    ])
    func unknownKeyHasNoIcon(json: String) throws {
        let category = try mapper.mapCategory(Self.decode(icon: json))

        #expect(category.icon == nil)
        #expect(category.label == "Label")
    }
}

// MARK: - Helpers

private extension PolymarketCategoryIconMappingTests {
    static func decode(icon: String) throws -> PolymarketDTO.Category {
        let json = #"{"id": 7, "label": "Label", "icon": \#(icon), "hasSeries": false}"#

        return try JSONDecoder().decode(PolymarketDTO.Category.self, from: Data(json.utf8))
    }
}
