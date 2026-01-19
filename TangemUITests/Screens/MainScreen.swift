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
    private lazy var buyActionButton = staticText(.buyTitle)
    private lazy var swapActionButton = staticText(.exchangeTitle)
    private lazy var sellActionButton = staticText(.sellTitle)
    private lazy var tokensList = otherElement(.tokensList)
    private lazy var organizeTokensButton = button(.organizeTokensButton)
    private lazy var detailsButton = button(.detailsButton)
    private lazy var actionButtonsList = otherElement(.actionButtonsList)
    private lazy var headerCardImage = image(.headerCardImage)
    private lazy var totalBalance = staticText(.totalBalance)
    private lazy var totalBalanceShimmer = otherElement(.totalBalanceShimmer)
    private lazy var missingDerivationNotification = otherElement(.missingDerivationNotification)

    @discardableResult
    func validate(cardType: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Validate MainPage for card type: \(cardType.rawValue)") { _ in
            validateHeaderCardImage(for: cardType)

            switch cardType {
            case .twin, .xrpNote, .xlmBird:
                XCTAssertTrue(actionButtonsList.waitForExistence(timeout: .robustUIUpdate), "Action buttons list should exist for twin cards")

                let buttonTexts = actionButtonsList.buttons.allElementsBoundByIndex.map { $0.label }
                XCTAssertTrue(buttonTexts.contains("Buy"), "Buy button should exist")
                XCTAssertTrue(buttonTexts.contains("Receive"), "Receive button should exist")
            case .wallet, .wallet2, .walletDemo, .wallet2Demo, .shiba, .four12, .v3seckp, .ring:
                XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")
                XCTAssertTrue(buyActionButton.waitForExistence(timeout: .robustUIUpdate), "Buy button should exist for wallet cards")
                XCTAssertTrue(swapActionButton.exists, "Exchange button should exist for wallet cards")
                XCTAssertTrue(sellActionButton.exists, "Sell button should exist for wallet cards")
            default:
                XCTFail("Provide card verification methods for card type: \(String(describing: cardType))")
            }
        }
        return self
    }

    // MARK: - Main action buttons

    @discardableResult
    func tapMainBuy() -> BuyTokenSelectorScreen {
        XCTContext.runActivity(named: "Tap Buy action on main screen") { _ in
            waitAndAssertTrue(buyActionButton, "Buy title should exist on main screen")
            buyActionButton.waitAndTap()
            return BuyTokenSelectorScreen(app)
        }
    }

    @discardableResult
    func tapMainSwap() -> SwapTokenSelectorScreen {
        XCTContext.runActivity(named: "Tap Exchange action on main screen") { _ in
            waitAndAssertTrue(swapActionButton, "Exchange title should exist on main screen")
            swapActionButton.waitAndTap()
            return SwapTokenSelectorScreen(app)
        }
    }

    @discardableResult
    func tapMainSell() -> SellTokenSelectorScreen {
        XCTContext.runActivity(named: "Tap Sell action on main screen") { _ in
            waitAndAssertTrue(sellActionButton, "Sell title should exist on main screen")
            sellActionButton.waitAndTap()
            return SellTokenSelectorScreen(app)
        }
    }

    func tapToken(_ label: String) -> TokenScreen {
        XCTContext.runActivity(named: "Tap token with label: \(label)") { _ in
            XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")
            tokensList.staticTextByLabel(label: label).waitAndTap()
            return TokenScreen(app)
        }
    }

    @discardableResult
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

    @discardableResult
    func waitDeveloperCardBannerExists() -> Self {
        XCTContext.runActivity(named: "Wait developer card banner exists") { _ in
            let bannerElement = app.staticTexts[MainAccessibilityIdentifiers.developerCardBanner]
            waitAndAssertTrue(bannerElement, "Developer card banner should be displayed")
        }
        return self
    }

    @discardableResult
    func waitDeveloperCardBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Wait developer card banner not exists") { _ in
            let bannerElement = app.staticTexts[MainAccessibilityIdentifiers.developerCardBanner]
            XCTAssertFalse(bannerElement.exists, "Developer card banner should not be displayed")
        }
        return self
    }

    @discardableResult
    func validateMandatorySecurityUpdateBannerExists() -> Self {
        XCTContext.runActivity(named: "Validate mandatory security update banner exists") { _ in
            let bannerElement = app.otherElements[MainAccessibilityIdentifiers.mandatorySecurityUpdateBanner]
            waitAndAssertTrue(bannerElement, "Mandatory security update banner should be displayed")
        }
        return self
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

    @discardableResult
    func openDetails() -> DetailsScreen {
        XCTContext.runActivity(named: "Open details screen") { _ in
            detailsButton.waitAndTap()
            return DetailsScreen(app)
        }
    }

    @discardableResult
    func longPressWalletHeader() -> Self {
        XCTContext.runActivity(named: "Long press wallet header") { _ in
            waitAndAssertTrue(headerCardImage, "Header card image should exist")
            headerCardImage.press(forDuration: 1.0)
        }
        return self
    }

    func longPressToken(_ tokenName: String) -> ContextMenuScreen {
        XCTContext.runActivity(named: "Long press token: \(tokenName)") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            let tokenElement = tokensList.staticTextByLabel(label: tokenName)
            waitAndAssertTrue(tokenElement, "Token '\(tokenName)' should exist")
            tokenElement.press(forDuration: 1.0)
            return ContextMenuScreen(app)
        }
    }

    @discardableResult
    func waitForNoRenameButton() -> Self {
        XCTContext.runActivity(named: "Wait for no rename button exists") { _ in
            let renameButton = app.buttons["Rename"]
            XCTAssertFalse(renameButton.exists, "Rename button should not exist in context menu")
        }
        return self
    }

    @discardableResult
    func waitForNoDeleteButton() -> Self {
        XCTContext.runActivity(named: "Wait for delete button exists") { _ in
            let deleteButton = app.buttons["Delete"]
            XCTAssertFalse(deleteButton.exists, "Delete button should not exist in context menu")
        }
        return self
    }

    @discardableResult
    func waitForDeleteButtonExists() -> Self {
        XCTContext.runActivity(named: "Wait for delete button exists") { _ in
            let deleteButton = app.buttons["Delete"]
            waitAndAssertTrue(deleteButton, "Delete button should exist in context menu")
        }
        return self
    }

    @discardableResult
    func waitForTotalBalanceDisplayedAsDash() -> Self {
        XCTContext.runActivity(named: "Wait for total balance displayed as dash") { _ in
            waitAndAssertTrue(totalBalance, "Total balance element should exist")
            XCTAssertTrue(totalBalance.label.contains("–"), "Total balance should be displayed as dash")
        }
        return self
    }

    @discardableResult
    func waitForTotalBalanceDisplayed() -> Self {
        XCTContext.runActivity(named: "Wait for total balance displayed") { _ in
            waitAndAssertTrue(totalBalance, "Total balance should be displayed")
            return self
        }
    }

    func getTotalBalanceValue() -> String {
        XCTContext.runActivity(named: "Get total balance value") { _ in
            waitAndAssertTrue(totalBalance, "Total balance element should exist")
            return totalBalance.label
        }
    }

    func getTotalBalanceNumericValue() -> Decimal {
        XCTContext.runActivity(named: "Get total balance numeric value") { _ in
            let balanceText = getTotalBalanceValue()
            return NumericValueHelper.parseNumericValue(from: balanceText)
        }
    }

    @discardableResult
    func verifyTotalBalanceDecreased(from previousBalance: Decimal) -> Self {
        XCTContext.runActivity(named: "Verify total balance decreased from \(previousBalance)") { _ in
            let currentBalance = getTotalBalanceNumericValue()
            XCTAssertLessThan(currentBalance, previousBalance, "Current balance (\(currentBalance)) should be less than previous balance (\(previousBalance))")
            return self
        }
    }

    func getTokenCount(tokenName: String) -> Int {
        XCTContext.runActivity(named: "Get count of tokens with name: \(tokenName)") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")

            // Get all balance elements with the same accessibility identifier
            let balanceElements = tokensList.staticTexts.matching(identifier: MainAccessibilityIdentifiers.tokenBalance(for: tokenName))

            // Wait for elements to be available
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "count >= 0"),
                object: balanceElements
            )
            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)
            XCTAssertEqual(result, .completed, "Should be able to query balance elements for token '\(tokenName)'")

            return balanceElements.count
        }
    }

    func getAllTokenBalances(tokenName: String) -> [String] {
        XCTContext.runActivity(named: "Get all balances for token: \(tokenName)") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")

            // Get all balance elements with the same accessibility identifier
            let balanceElements = tokensList.staticTexts.matching(identifier: MainAccessibilityIdentifiers.tokenBalance(for: tokenName))

            // Wait for at least one element to exist
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "count > 0"),
                object: balanceElements
            )
            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)
            XCTAssertEqual(result, .completed, "Should have balance elements for token '\(tokenName)'")

            let allBalanceElements = balanceElements.allElementsBoundByIndex

            // Validate that we have at least one element
            XCTAssertGreaterThan(
                allBalanceElements.count,
                0,
                "Token '\(tokenName)' should have at least one balance element"
            )

            // Return all balance labels
            return allBalanceElements.map { $0.label }
        }
    }

    func getAllTokenBalancesNumeric(tokenName: String) -> [Decimal] {
        XCTContext.runActivity(named: "Get all balances (numeric) for token: \(tokenName)") { _ in
            let labels = getAllTokenBalances(tokenName: tokenName)
            return labels.map { NumericValueHelper.parseNumericValue(from: $0) }
        }
    }

    func getTokenBalance(tokenName: String, tokenIndex: Int = 0) -> String {
        XCTContext.runActivity(named: "Get balance for token: \(tokenName) at index: \(tokenIndex)") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")

            // Get all balance elements with the same accessibility identifier
            let balanceElements = tokensList.staticTexts.matching(identifier: MainAccessibilityIdentifiers.tokenBalance(for: tokenName))

            // Wait for at least one element to exist
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "count > 0"),
                object: balanceElements
            )
            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)
            XCTAssertEqual(result, .completed, "Should have balance elements for token '\(tokenName)'")

            let allBalanceElements = balanceElements.allElementsBoundByIndex

            // Validate that we have enough elements for the requested index
            XCTAssertGreaterThan(
                allBalanceElements.count,
                tokenIndex,
                "Token '\(tokenName)' should have at least \(tokenIndex + 1) balance elements, but found \(allBalanceElements.count)"
            )

            // Get the specific element at the requested index
            let balanceElement = allBalanceElements[tokenIndex]
            waitAndAssertTrue(balanceElement, "Balance element should exist for token '\(tokenName)' at index \(tokenIndex)")

            return balanceElement.label
        }
    }

    func getTokenBalanceNumeric(tokenName: String, tokenIndex: Int = 0) -> Decimal {
        XCTContext.runActivity(named: "Get balance (numeric) for token: \(tokenName) at index: \(tokenIndex)") { _ in
            let label = getTokenBalance(tokenName: tokenName, tokenIndex: tokenIndex)
            return NumericValueHelper.parseNumericValue(from: label)
        }
    }

    @discardableResult
    func waitForTotalBalanceContainsCurrency(_ currencySymbol: String) -> Self {
        XCTContext.runActivity(named: "Validate total balance contains currency symbol: \(currencySymbol)") { _ in
            waitAndAssertTrue(totalBalance, "Total balance element should exist")
            let balanceText = totalBalance.label
            XCTAssertTrue(balanceText.contains(currencySymbol), "Total balance should contain '\(currencySymbol)' but was '\(balanceText)'")
        }
        return self
    }

    @discardableResult
    func waitForTotalBalanceShimmer() -> Self {
        XCTContext.runActivity(named: "Wait for total balance shimmer effect") { _ in
            waitAndAssertTrue(totalBalanceShimmer, "Total balance shimmer should be displayed")
        }
        return self
    }

    @discardableResult
    func waitForTotalBalanceShimmerToDisappear() -> Self {
        XCTContext.runActivity(named: "Wait for total balance shimmer to disappear") { _ in
            XCTAssertTrue(totalBalanceShimmer.waitForNonExistence(timeout: .robustUIUpdate), "Total balance shimmer should disappear")
        }
        return self
    }

    @discardableResult
    func waitForTotalBalanceShimmerToComplete() -> Self {
        XCTContext.runActivity(named: "Wait for total balance shimmer to complete and show final content") { _ in
            // First wait for shimmer to disappear
            XCTAssertTrue(totalBalanceShimmer.waitForNonExistence(timeout: .robustUIUpdate), "Total balance shimmer should disappear")

            // Then wait for final content to appear
            waitAndAssertTrue(totalBalance, "Total balance should be displayed")
            XCTAssertFalse(totalBalance.label.isEmpty, "Total balance should have content")
        }
        return self
    }

    @discardableResult
    func waitForSynchronizeAddressesButtonExists() -> Self {
        XCTContext.runActivity(named: "Wait for synchronize addresses button exists") { _ in
            waitAndAssertTrue(missingDerivationNotification, "Missing derivation notification should exist")
        }
        return self
    }

    @discardableResult
    func waitActionButtonsEnabled() -> Self {
        XCTContext.runActivity(named: "Validate action buttons are enabled") { _ in
            waitAndAssertTrue(buyActionButton, "Buy button should exist")
            waitAndAssertTrue(swapActionButton, "Exchange button should exist")
            waitAndAssertTrue(sellActionButton, "Sell button should exist")

            XCTAssertTrue(buyActionButton.isEnabled, "Buy button should be enabled")
            XCTAssertTrue(swapActionButton.isEnabled, "Exchange button should be enabled")
            XCTAssertTrue(sellActionButton.isEnabled, "Sell button should be enabled")
        }
        return self
    }

    @discardableResult
    func waitActionButtonsDisabled() -> Self {
        XCTContext.runActivity(named: "Validate action buttons are disabled") { _ in
            waitAndAssertTrue(buyActionButton, "Buy button should exist")
            waitAndAssertTrue(swapActionButton, "Exchange button should exist")
            waitAndAssertTrue(sellActionButton, "Sell button should exist")

            XCTAssertFalse(buyActionButton.isEnabled, "Buy button should be disabled")
            XCTAssertFalse(swapActionButton.isEnabled, "Exchange button should be disabled")
            XCTAssertFalse(sellActionButton.isEnabled, "Sell button should be disabled")
        }
        return self
    }

    @discardableResult
    func openMarketsSheetWithSwipe() -> MarketsScreen {
        XCTContext.runActivity(named: "Open markets sheet with swipe up gesture") { _ in
            // Find the grabber view or bottom sheet area to swipe up
            let grabberView = app.otherElements.matching(identifier: "commonUIGrabber").firstMatch

            waitAndAssertTrue(grabberView)

            // Swipe up on the grabber view
            let startPoint = grabberView.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let endPoint = startPoint.withOffset(CGVector(dx: 0, dy: -300))
            startPoint.press(forDuration: 0.2, thenDragTo: endPoint)

            return MarketsScreen(app)
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
    case actionButtonsList
    case headerCardImage
    case totalBalance
    case totalBalanceShimmer
    case missingDerivationNotification

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
        case .actionButtonsList:
            TokenAccessibilityIdentifiers.actionButtonsList
        case .headerCardImage:
            MainAccessibilityIdentifiers.headerCardImage
        case .totalBalance:
            MainAccessibilityIdentifiers.totalBalance
        case .totalBalanceShimmer:
            "\(MainAccessibilityIdentifiers.totalBalance)Shimmer"
        case .missingDerivationNotification:
            MainAccessibilityIdentifiers.missingDerivationNotification
        }
    }
}

extension MainScreen {
    private func validateHeaderCardImage(for cardType: CardMockAccessibilityIdentifiers) {
        XCTContext.runActivity(named: "Validate header card image for card type: \(cardType.rawValue)") { _ in
            switch cardType {
            case .xlmBird, .v3seckp:
                break
            default:
                XCTAssertTrue(
                    headerCardImage.waitForExistence(timeout: .robustUIUpdate),
                    "Header card image should be present for card type: \(cardType.rawValue)"
                )
            }
        }
    }
}
