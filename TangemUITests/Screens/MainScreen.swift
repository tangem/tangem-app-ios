//
//  MainScreen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers
import Foundation

final class MainScreen: ScreenBase<MainScreenElement> {
    private lazy var buyTitle = staticText(.buyTitle)
    private lazy var exchangeTitle = staticText(.exchangeTitle)
    private lazy var sellTitle = staticText(.sellTitle)
    private lazy var tokensList = otherElement(.tokensList)
    private lazy var organizeTokensButton = button(.organizeTokensButton)
    private lazy var detailsButton = button(.detailsButton)

    func validate() {
        XCTContext.runActivity(named: "Validate MainPage") { _ in
            XCTAssertTrue(buyTitle.waitForExistence(timeout: .robustUIUpdate))
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
            // Ensure tokens list is loaded first
            XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")

            // Try to find the organize button and scroll to it if needed
            if !organizeTokensButton.exists || !organizeTokensButton.isHittable {
                // Scroll to find the organize button with better error handling
                scrollToElement(organizeTokensButton, attempts: .standard)

                // Wait for the button to become hittable after scrolling
                XCTAssertTrue(
                    organizeTokensButton.waitForState(state: .hittable, for: .robustUIUpdate),
                    "Organize tokens button should become hittable after scrolling"
                )
            }

            // Use the robust waitAndTap method instead of direct tap
            XCTAssertTrue(
                organizeTokensButton.waitAndTap(timeout: .robustUIUpdate),
                "Should successfully tap organize tokens button"
            )

            return OrganizeTokensScreen(app)
        }
    }

    func validateTokenNotExists(_ label: String) {
        _ = tokensList.waitForExistence(timeout: .robustUIUpdate)
        XCTContext.runActivity(named: "Validate token with label '\(label)' does not exist") { _ in
            let tokenElement = tokensList.staticTextByLabel(label: label)
            XCTAssertFalse(tokenElement.exists, "Token with label '\(label)' should not exist in the list")
        }
    }

    func getTokensOrder() -> [String] {
        XCTContext.runActivity(named: "Get tokens order from main screen") { _ in
            // Wait for tokens list to be available
            XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")

            // Wait for token elements to be stable - use predicate expectation
            let tokenTitleQuery = tokensList.staticTexts.matching(identifier: MainAccessibilityIdentifiers.tokenTitle)

            // Wait until we have stable token elements
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "count > 0"),
                object: tokenTitleQuery
            )

            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)
            XCTAssertEqual(result, .completed, "Should have token title elements available")

            // Get all token title elements and ensure they're stable
            let tokenTitleElements = tokenTitleQuery.allElementsBoundByIndex

            // Filter out elements that are not properly loaded or visible
            let stableElements = tokenTitleElements.filter { element in
                element.exists && element.isHittable && !element.label.isEmpty
            }

            // Sort by Y-coordinate (top to bottom) and return labels
            let sortedElements = stableElements.sorted { element1, element2 in
                // Add small tolerance for Y-coordinate comparison to handle minor positioning differences
                let tolerance: CGFloat = 1.0
                let diff = element1.frame.minY - element2.frame.minY

                if abs(diff) < tolerance {
                    // If elements are at roughly the same Y position, sort by X coordinate (left to right)
                    return element1.frame.minX < element2.frame.minX
                } else {
                    return diff < 0
                }
            }

            let labels = sortedElements.map { $0.label }

            // Add diagnostic information for debugging
            if labels.isEmpty {
                let allTexts = tokensList.staticTexts.allElementsBoundByIndex.map {
                    "[\($0.identifier): '\($0.label)']"
                }.joined(separator: ", ")
                XCTFail("No token titles found. Available static texts: \(allTexts)")
            }

            return labels
        }
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
            _ = tokensList.waitForExistence(timeout: .robustUIUpdate)
            let actualState = isGrouped()
            XCTAssertEqual(actualState, expectedState, "Expected grouping state on main screen: \(expectedState), but got: \(actualState)")
        }
        return self
    }

    func openDetails() -> DetailsScreen {
        XCTContext.runActivity(named: "Open details screen") { _ in
            detailsButton.waitAndTap()
            return DetailsScreen(app)
        }
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
    case detailsButton

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
        case .detailsButton:
            MainAccessibilityIdentifiers.detailsButton
        }
    }
}
