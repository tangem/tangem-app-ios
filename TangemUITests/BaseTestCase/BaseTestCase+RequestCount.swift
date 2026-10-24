//
//  BaseTestCase+RequestCount.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

extension BaseTestCase {
    func wireMockRequestCount(method: String = "GET", urlPattern: String) -> Int {
        wireMockClient.requestCountSync(method: method, urlPattern: urlPattern)
    }

    func waitForWireMockRequestCount(method: String = "GET", urlPattern: String, toExceed previousCount: Int) {
        XCTContext.runActivity(named: "Wait for \(method) request matching '\(urlPattern)'") { _ in
            let predicate = NSPredicate { [self] _, _ in
                wireMockRequestCount(method: method, urlPattern: urlPattern) > previousCount
            }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "A \(method) request matching '\(urlPattern)' should be sent more than \(previousCount) times"
            )
        }
    }
}
