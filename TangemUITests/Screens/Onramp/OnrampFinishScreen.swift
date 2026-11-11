//
//  OnrampFinishScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampFinishScreen: ScreenBase<OnrampFinishScreenElement> {
    @discardableResult
    func verifyTransactionDate(between start: Date, and end: Date) -> Self {
        XCTContext.runActivity(named: "Validate transaction date and time") { _ in
            let formatter = DateFormatter()
            formatter.locale = UITestLocale.locale
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            let acceptedDates = Set([start, end].map { formatter.string(from: $0) })
            let dateText = acceptedDates
                .map { element(containing: $0) }
                .first { $0.waitForExistence(timeout: .robustUIUpdate) }
            XCTAssertNotNil(dateText, "Transaction date should contain one of \(acceptedDates)")
        }
        return self
    }

    @discardableResult
    func verifyPurchaseDetails(fiatAmount expectedFiat: String, cryptoAmount expectedCrypto: String, provider: String) -> Self {
        XCTContext.runActivity(named: "Validate purchase details") { _ in
            waitAndAssertTrue(row(Localization.txHistoryYouPaid, containing: expectedFiat), "'You paid' should show '\(expectedFiat)'")
            waitAndAssertTrue(row(Localization.onrampTitleYouGet, containing: expectedCrypto), "'You get' should show '\(expectedCrypto)'")
            waitAndAssertTrue(row(Localization.expressProvider, containing: provider), "'Provider' should show '\(provider)'")
        }
        return self
    }

    @discardableResult
    func verifyTransactionStatus(_ expectedStatus: String) -> Self {
        XCTContext.runActivity(named: "Validate transaction status '\(expectedStatus)' and footer") { _ in
            waitAndAssertTrue(app.staticTexts[expectedStatus].firstMatch, "Transaction status '\(expectedStatus)' should be the title")
            waitAndAssertTrue(
                app.staticTexts[Localization.onrampTransactionStatusFooterText].firstMatch,
                "Transaction status footer should exist"
            )
        }
        return self
    }

    @discardableResult
    func waitForCloseButton() -> Self {
        XCTContext.runActivity(named: "Validate Close button") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist")
        }
        return self
    }

    func tapClose<Destination: Screen>(to destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Tap Close on the status screen") { _ in
            closeButton.waitAndTap()
            let footer = app.staticTexts[Localization.onrampTransactionStatusFooterText].firstMatch
            XCTAssertTrue(footer.waitForState(state: .doesntExist, for: .robustUIUpdate), "Status screen should be dismissed")
            return Destination(app)
        }
    }

    private var closeButton: XCUIElement {
        app.buttons[Localization.commonClose].firstMatch
    }

    private func row(_ title: String, containing value: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", title, value))
            .firstMatch
    }

    private func element(containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}

enum OnrampFinishScreenElement: String, UIElement {
    case none

    var accessibilityIdentifier: String {
        rawValue
    }
}
