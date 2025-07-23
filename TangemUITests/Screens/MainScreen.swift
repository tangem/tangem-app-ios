//
//  MainScreen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class MainScreen: ScreenBase<MainScreenElement> {
    private lazy var buyTitle = staticText(.buyTitle)
    private lazy var exchangeTitle = staticText(.exchangeTitle)
    private lazy var sellTitle = staticText(.sellTitle)
    private lazy var tokensList = otherElement(.tokensList)
    private lazy var organizeTokensButton = button(.organizeTokensButton)

    func validate() {
        XCTContext.runActivity(named: "Validate MainPage") { _ in
            XCTAssertTrue(buyTitle.waitForExistence(timeout: .quickUIUpdate))
            XCTAssertTrue(exchangeTitle.exists)
            XCTAssertTrue(sellTitle.exists)
        }
    }

    func tapToken(_ label: String) -> TokenScreen {
        XCTContext.runActivity(named: "Tap token with label: \(label)") { _ in
            tokensList.staticTextByLabel(label: label).waitAndTap()
            return TokenScreen(app)
        }
    }

    func organizeTokens() -> OrganizeTokensScreen {
        XCTContext.runActivity(named: "Open organize tokens screen") { _ in
            // First scroll to the button if it's not visible
            if !organizeTokensButton.exists || !organizeTokensButton.isHittable {
                // Method 1: Scroll inside the tokens list
                tokensList.scrollToElement(organizeTokensButton)

                // Give time for scroll animation
                Thread.sleep(forTimeInterval: 0.5)
            }

            // Make sure the button exists and is available for tapping
            XCTAssertTrue(organizeTokensButton.waitForExistence(timeout: 3), "Organize tokens button should exist")

            organizeTokensButton.tap()
            return OrganizeTokensScreen(app)
        }
    }

    func validateTokenNotExists(_ label: String) {
        _ = tokensList.waitForExistence(timeout: .quickUIUpdate)
        XCTContext.runActivity(named: "Validate token with label '\(label)' does not exist") { _ in
            let tokenElement = tokensList.staticTextByLabel(label: label)
            XCTAssertFalse(tokenElement.exists, "Token with label '\(label)' should not exist in the list")
        }
    }

    func getTokensOrder() -> [String] {
        _ = tokensList.waitForExistence(timeout: .quickUIUpdate)
        // Get token names
        let tokenTitleElements = tokensList.staticTexts
            .matching(identifier: MainAccessibilityIdentifiers.tokenTitle)
            .allElementsBoundByIndex

        // Sort by Y-coordinate (top to bottom) and return labels
        return tokenTitleElements
            .sorted { $0.frame.minY < $1.frame.minY }
            .map { $0.label }
    }

    @discardableResult
    func verifyTokensOrder(_ expectedOrder: [String]) -> Self {
        XCTContext.runActivity(named: "Verify tokens order on main screen") { _ in
            let actualOrder = getTokensOrder()
            XCTAssertEqual(actualOrder, expectedOrder, "Tokens order on main screen doesn't match expected")
        }
        return self
    }

    @discardableResult
    func verifyIsGrouped(_ expectedState: Bool) -> Self {
        XCTContext.runActivity(named: "Verify tokens grouping state on main screen is \(expectedState)") { _ in
            _ = tokensList.waitForExistence(timeout: .longUIUpdate)
            let actualState = isGrouped()
            XCTAssertEqual(actualState, expectedState, "Expected grouping state on main screen: \(expectedState), but got: \(actualState)")
        }
        return self
    }

    private func isGrouped() -> Bool {
        let networkHeaders = tokensList.descendants(matching: .staticText)
            .allElementsBoundByIndex
            .filter { element in
                let text = element.label
                return text.lowercased().contains("network")
            }

        return !networkHeaders.isEmpty
    }
}

enum MainScreenElement: String, UIElement {
    case buyTitle
    case exchangeTitle
    case sellTitle
    case tokensList
    case organizeTokensButton

    var accessibilityIdentifier: String {
        switch self {
        case .buyTitle:
            MainAccessibilityIdentifiers.buyTitle
        case .exchangeTitle:
            MainAccessibilityIdentifiers.exchangeTitle
        case .sellTitle:
            MainAccessibilityIdentifiers.sellTitle
        case .tokensList:
            MainAccessibilityIdentifiers.tokensList
        case .organizeTokensButton:
            MainAccessibilityIdentifiers.organizeTokensButton
        }
    }
}
