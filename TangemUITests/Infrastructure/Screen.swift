//
//  Screen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

protocol Screen {
    var app: XCUIApplication { get }
    init(_ app: XCUIApplication)
}

extension Screen {
    /// Taps the Back button and returns the screen the caller expects to land on.
    @discardableResult
    func tapBackButton<Destination: Screen>(to destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Tap Back button") { _ in
            // The app has two navigation bar components exposing different back-button identifiers.
            let predicate = NSPredicate(
                format: "identifier == %@ OR identifier == %@",
                CommonUIAccessibilityIdentifiers.backButton,
                "BackButton"
            )
            app.buttons.matching(predicate).firstMatch.waitAndTap()
            return Destination(app)
        }
    }

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
