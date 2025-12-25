//
//  MarketsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

final class MarketsScreen: ScreenBase<MarketsScreenElement> {
    private lazy var searchField = textField(.searchThroughMarketField)
    private lazy var addToPortfolioButton = button(.addToPortfolioButton)
    private lazy var mainNetworkSwitch = switchElement(.mainNetworkSwitch)
    private lazy var continueButton = button(.continueButton)

    @discardableResult
    func closeMarketsSheetWithSwipe() -> MainScreen {
        XCTContext.runActivity(named: "Close markets sheet with swipe down gesture") { _ in
            // Find the grabber view or bottom sheet area to swipe down
            let grabberView = app.otherElements.matching(identifier: "commonUIGrabber").firstMatch

            waitAndAssertTrue(grabberView)

            // Swipe down on the grabber view
            let startPoint = grabberView.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let endPoint = startPoint.withOffset(CGVector(dx: 0, dy: 400)) // Swipe down 300 points
            startPoint.press(forDuration: 0.1, thenDragTo: endPoint)

            return MainScreen(app)
        }
    }

    @discardableResult
    func searchForToken(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Search for token: \(tokenName)") { _ in
            let marketsSearchField = app.textFields.matching(
                identifier: MainAccessibilityIdentifiers.searchThroughMarketField
            ).element(boundBy: 1)
            waitAndAssertTrue(marketsSearchField, "Markets search field should exist")
            marketsSearchField.tap()
            marketsSearchField.typeText(tokenName)
            return self
        }
    }

    @discardableResult
    func tapTokenInSearchResults(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Tap token in search results: \(tokenName)") { _ in
            let tokenButton = app.buttons[
                MarketsAccessibilityIdentifiers.marketsListTokenItem(uniqueId: tokenName)
            ]
            waitAndAssertTrue(tokenButton, "Token button should exist")
            tokenButton.tap()
            return self
        }
    }

    @discardableResult
    func openTokenDetails(_ tokenName: String) -> MarketsTokenDetailsScreen {
        tapTokenInSearchResults(tokenName)
        return MarketsTokenDetailsScreen(app)
    }

    @discardableResult
    func tapAddToPortfolioButton() -> Self {
        XCTContext.runActivity(named: "Tap Add to Portfolio button") { _ in
            XCTAssertTrue(
                addToPortfolioButton.waitForExistence(timeout: .robustUIUpdate),
                "Add to Portfolio button should exist"
            )
            addToPortfolioButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func toggleMainNetworkSwitch() -> Self {
        XCTContext.runActivity(named: "Toggle MAIN network switch") { _ in
            XCTAssertTrue(
                mainNetworkSwitch.waitForExistence(timeout: .robustUIUpdate),
                "MAIN network switch should exist"
            )
            mainNetworkSwitch.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapContinueButton() -> Self {
        XCTContext.runActivity(named: "Tap Continue button") { _ in
            XCTAssertTrue(
                continueButton.waitForExistence(timeout: .robustUIUpdate),
                "Continue button should exist"
            )
            continueButton.waitAndTap()
            return self
        }
    }

    func tapBackButton() -> Self {
        XCTContext.runActivity(named: "Tap Back button") { _ in
            app.buttons["Back"].waitAndTap()
            return self
        }
    }
}

enum MarketsScreenElement: String, UIElement {
    case searchThroughMarketField
    case addToPortfolioButton
    case mainNetworkSwitch
    case continueButton

    var accessibilityIdentifier: String {
        switch self {
        case .searchThroughMarketField:
            MainAccessibilityIdentifiers.searchThroughMarketField
        case .addToPortfolioButton:
            MainAccessibilityIdentifiers.addToPortfolioButton
        case .mainNetworkSwitch:
            TokenAccessibilityIdentifiers.mainNetworkSwitch
        case .continueButton:
            TokenAccessibilityIdentifiers.continueButton
        }
    }
}
