//
//  XCTestCase+Extensions.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

extension XCTestCase {
    func testStep(_ description: String, closure: () throws -> Void) {
        XCTContext.runActivity(named: "Step: \(description)") { _ in
            do {
                try closure()
            } catch {
                XCTFail("Failed to perform step: \(description)")
            }
        }
    }

    func checkCondition(
        _ description: String,
        _ condition: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTContext.runActivity(named: "Checking that \(description)") { _ in
            XCTAssertTrue(
                condition,
                "Check \"\(description)\" was unsuccessful",
                file: file,
                line: line
            )
        }
    }

    func checkEquality<T>(
        _ description: String,
        _ value: T,
        _ compareTo: T,
        file: StaticString = #file,
        line: UInt = #line
    ) where T: Equatable {
        XCTContext.runActivity(named: "Checking that \(description)") { _ in
            XCTAssertEqual(
                value,
                compareTo,
                file: file,
                line: line
            )
        }
    }

    func checkNotEqual<T>(
        _ description: String,
        _ value: T,
        _ compareTo: T,
        file: StaticString = #file,
        line: UInt = #line
    ) where T: Equatable {
        XCTContext.runActivity(named: "Checking that \(description)") { _ in
            XCTAssertNotEqual(
                value,
                compareTo,
                file: file,
                line: line
            )
        }
    }

    func skipDueToBug(_ bugId: String, description: String = "") throws {
        let reason = description.isEmpty ?
            "Skipping due to bug \(bugId)" :
            "Skipping due to bug \(bugId): \(description)"

        try XCTSkipIf(true, reason)
    }
}
