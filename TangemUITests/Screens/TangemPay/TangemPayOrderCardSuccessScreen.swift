//
//  TangemPayOrderCardSuccessScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayOrderCardSuccessScreen: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts[Constants.title].firstMatch
    private lazy var showCardButton = app.buttons[Constants.showCardTitle].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the Card ordered screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "'\(Constants.title)' should be displayed after placing the order")
            return self
        }
    }

    @discardableResult
    func verifyContent(deliveryDays: Int, email: String) -> Self {
        XCTContext.runActivity(named: "Verify the Card ordered screen content") { _ in
            let deliveryNote = "It will take up to \(deliveryDays) business days for delivery"
            let emailNote = "Within 3 business days you will receive an email from logistic company on \(email)"
            waitAndAssertTrue(app.staticTexts[deliveryNote].firstMatch, "'\(deliveryNote)' should be displayed")
            waitAndAssertTrue(app.staticTexts[emailNote].firstMatch, "'\(emailNote)' should be displayed")
            waitAndAssertTrue(showCardButton, "'\(Constants.showCardTitle)' button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapShowCard<Destination: Screen>(to destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Tap Show card") { _ in
            showCardButton.waitAndTap()
            XCTAssertTrue(title.waitForNonExistence(timeout: .robustUIUpdate), "Card ordered screen should be dismissed")
            return Destination(app)
        }
    }
}

private extension TangemPayOrderCardSuccessScreen {
    enum Constants {
        static let title = "Card ordered"
        static let showCardTitle = "Show card"
    }
}
