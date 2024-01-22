//
//  CurrencyTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class CurrencyTests: XCTestCase {
    func testAnalyticsDescriptionContainsCode() {
        let currency = CurrenciesResponse.Currency(
            id: "784",
            code: "aud",
            name: "Australian Dollar",
            unit: "dollar"
        )

        XCTAssertEqual(currency.analyticsDescription, "Australian Dollar (AUD)")
    }
}
