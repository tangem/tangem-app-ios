//
//  SendFinishScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendFinishScreen: ScreenBase<SendFinishScreenElement> {
    private lazy var headerTitle = staticText(.headerTitle)
    private lazy var transactionTime = staticText(.transactionTime)
    private lazy var exploreButton = button(.exploreButton)
    private lazy var shareButton = button(.shareButton)
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait for display: Send Finish Screen") { _ in
            waitAndAssertTrue(headerTitle, "Finish header title should be displayed")
            waitAndAssertTrue(transactionTime, "Transaction time should be displayed")
            waitAndAssertTrue(closeButton, "Close button should be displayed")
            return self
        }
    }

    @discardableResult
    func assertHeaderTitle(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Assert finish header title is '\(expected)'") { _ in
            waitAndAssertTrue(headerTitle, "Finish header title should be displayed")
            let predicate = NSPredicate(format: "label == %@", expected)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: headerTitle)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Finish header title should be '\(expected)' but was '\(headerTitle.label)'"
            )
            return self
        }
    }

    @discardableResult
    func tapExploreButton() -> Self {
        XCTContext.runActivity(named: "Tap Explore button on Send Finish screen") { _ in
            waitAndAssertTrue(exploreButton, "Explore button should exist")
            exploreButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func waitForBrowserOpened() -> Self {
        XCTContext.runActivity(named: "Verify in-app browser is opened") { _ in
            let webView = app.webViews.firstMatch
            waitAndAssertTrue(webView, "Web view should appear after tapping Explore")
            return self
        }
    }

    @discardableResult
    func dismissBrowser() -> Self {
        XCTContext.runActivity(named: "Dismiss in-app browser") { _ in
            app.otherElements["TopBrowserBar"].buttons["Close"].waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapCloseButton() -> TokenScreen {
        XCTContext.runActivity(named: "Tap Close button on Send Finish screen") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist")
            closeButton.waitAndTap()
        }
        return TokenScreen(app)
    }
}

enum SendFinishScreenElement: String, UIElement {
    case headerTitle
    case transactionTime
    case exploreButton
    case shareButton
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .headerTitle:
            return SendAccessibilityIdentifiers.finishHeader
        case .transactionTime:
            return SendAccessibilityIdentifiers.finishTransactionTime
        case .exploreButton:
            return SendAccessibilityIdentifiers.finishExploreButton
        case .shareButton:
            return SendAccessibilityIdentifiers.finishShareButton
        case .closeButton:
            return SendAccessibilityIdentifiers.sendViewNextButton
        }
    }
}
