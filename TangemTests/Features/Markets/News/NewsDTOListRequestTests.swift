//
//  NewsDTOListRequestTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Testing
@testable import Tangem

@Suite(.tags(.news))
struct NewsDTOListRequestTests {
    @Test("Includes basic request parameters")
    func includesBasicRequestParameters() {
        let request = NewsDTO.List.Request(page: 2, limit: 50)

        #expect(request.parameters["page"] as? Int == 2)
        #expect(request.parameters["limit"] as? Int == 50)
    }

    @Test("Includes optional lang and asOf")
    func includesOptionalLangAndAsOf() {
        let request = NewsDTO.List.Request(page: 1, limit: 20, lang: "en", asOf: "2026-02-09T00:00:00Z")

        #expect(request.parameters["lang"] as? String == "en")
        #expect(request.parameters["asOf"] as? String == "2026-02-09T00:00:00Z")
    }

    @Test("Formats categoryIds as comma-separated string", arguments: Self.categoryCases())
    func formatsCategoryIdsAsCommaSeparatedString(categoryIds: [Int], expected: String?) {
        let request = NewsDTO.List.Request(categoryIds: categoryIds)

        #expect(request.parameters["categoryIds"] as? String == expected)
    }

    @Test("Formats tokenIds as comma-separated string", arguments: Self.tokenCases())
    func formatsTokenIdsAsCommaSeparatedString(tokenIds: [String], expected: String?) {
        let request = NewsDTO.List.Request(tokenIds: tokenIds)

        #expect(request.parameters["tokenIds"] as? String == expected)
    }
}

private extension NewsDTOListRequestTests {
    static func categoryCases() -> [([Int], String?)] {
        [
            ([], nil),
            ([1], "1"),
            ([1, 7, 42], "1,7,42"),
        ]
    }

    static func tokenCases() -> [([String], String?)] {
        [
            ([], nil),
            (["btc"], "btc"),
            (["btc", "eth"], "btc,eth"),
        ]
    }
}
