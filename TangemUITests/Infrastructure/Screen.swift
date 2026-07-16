//
//  Screen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

protocol Screen {
    var app: XCUIApplication { get }
}

extension Screen {
    /// Waits for element existence and then asserts it exists
    /// - Parameters:
    ///   - element: The element to wait for and assert
    ///   - timeout: Timeout for waiting (defaults to robustUIUpdate)
    ///   - message: Optional message for the assertion
    func waitAndAssertTrue(
        _ element: XCUIElement,
        timeout: TimeInterval = .robustUIUpdate,
        _ message: String? = nil
    ) {
        let elementExists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(
            elementExists,
            message ?? "Element should exist after waiting for \(timeout) seconds"
        )
    }
}
