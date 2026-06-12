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
    private lazy var addAndManageOrganizeRow = app.buttons[TokensManagementChooserAccessibilityIdentifiers.organizeTokensRow].firstMatch
    private lazy var detailsButton = button(.detailsButton)
    private lazy var actionButtonsList = otherElement(.actionButtonsList)
    private lazy var headerCardImage = image(.headerCardImage)
    private lazy var totalBalance = staticText(.totalBalance)
    private lazy var totalBalanceShimmer = otherElement(.totalBalanceShimmer)
    /// Type-agnostic: redesign exposes this as `Button`, legacy as `Other`. Drop after redesign rollout.
    private lazy var missingDerivationNotification = app.descendants(matching: .any)
        .matching(identifier: MainAccessibilityIdentifiers.missingDerivationNotification)
        .firstMatch
    private lazy var walletLockedNotification = button(.walletLockedNotification)
    private lazy var grabber = app.otherElements[CommonUIAccessibilityIdentifiers.grabber].firstMatch
    private lazy var tangemPayTile = app.buttons[TangemPayAccessibilityIdentifiers.mainScreenTile].firstMatch

    @discardableResult
    func validate(cardType: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Validate MainPage for card type: \(cardType.rawValue)") { _ in
            validateMainHeader(for: cardType)

            switch cardType {
            case .twin, .xrpNote, .xlmBird:
                XCTAssertTrue(actionButtonsList.waitForExistence(timeout: .robustUIUpdate), "Action buttons list should exist for twin cards")
            case .wallet, .wallet2, .walletDemo, .wallet2Demo, .shiba, .four12, .v3seckp, .ring:
                XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")
                XCTAssertTrue(buyActionButton.waitForExistence(timeout: .robustUIUpdate), "Buy button should exist for wallet cards")
                XCTAssertTrue(swapActionButton.exists, "Exchange button should exist for wallet cards")
                XCTAssertTrue(sellActionButton.exists, "Sell button should exist for wallet cards")
            default:
                XCTFail("Provide card verification methods for card type: \(String(describing: cardType))")
            }
            return self
        }
    }

    @discardableResult
    func waitForSwapButtonNotAvailable() -> Self {
        XCTContext.runActivity(named: "Verify Swap button is not available on single-currency card") { _ in
            waitAndAssertTrue(actionButtonsList, "Action buttons list should exist")
            let buttonTexts = actionButtonsList.buttons.allElementsBoundByIndex.map { $0.label }
            XCTAssertFalse(buttonTexts.contains("Swap"), "Swap button should not be available on single-currency cards")
            XCTAssertFalse(buttonTexts.contains("Exchange"), "Exchange button should not be available on single-currency cards")
            return self
        }
    }

    @discardableResult
    func verifyTradeActionButtonsHidden() -> Self {
        XCTContext.runActivity(named: "Verify Buy/Sell/Swap action buttons are hidden") { _ in
            waitAndAssertTrue(detailsButton, "Main screen should be loaded")
            XCTAssertFalse(buyActionButton.waitForExistence(timeout: .conditional), "Buy button should be hidden for S2C cards")
            XCTAssertFalse(swapActionButton.exists, "Swap button should be hidden for S2C cards")
            XCTAssertFalse(sellActionButton.exists, "Sell button should be hidden for S2C cards")
            return self
        }
    }

    @discardableResult
    func tapSendButton() -> SendScreen {
        XCTContext.runActivity(named: "Tap Send action button on main screen") { _ in
            waitAndAssertTrue(actionButtonsList, "Action buttons list should exist")
            actionButtonsList.buttons["Send"].waitAndTap()
            return SendScreen(app)
        }
    }

    // MARK: - Organize Tokens Button Visibility

    @discardableResult
    func verifyOrganizeTokensButtonVisible() -> Self {
        XCTContext.runActivity(named: "Verify organize tokens button IS visible") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            scrollTokensListToVisible(organizeTokensButton)
            waitAndAssertTrue(organizeTokensButton, "Organize tokens button should be visible on main screen")
            return self
        }
    }

    @discardableResult
    func verifyOrganizeTokensButtonNotVisible() -> Self {
        XCTContext.runActivity(named: "Verify organize tokens button is NOT visible") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            XCTAssertFalse(
                organizeTokensButton.waitForExistence(timeout: .conditional),
                "Organize tokens button should NOT be visible on main screen"
            )
            return self
        }
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
    func tapMainSwap() -> SwapStoriesScreen {
        XCTContext.runActivity(named: "Tap Exchange action on main screen") { _ in
            waitAndAssertTrue(swapActionButton, "Exchange title should exist on main screen")
            swapActionButton.waitAndTap()
            return SwapStoriesScreen(app)
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

    @discardableResult
    func tapMainBuyWhenUnavailable() -> Self {
        XCTContext.runActivity(named: "Tap Buy action on main screen (unavailable state)") { _ in
            waitAndAssertTrue(buyActionButton, "Buy title should exist on main screen")
            buyActionButton.tap()
            return self
        }
    }

    @discardableResult
    func tapMainSwapWhenUnavailable() -> Self {
        XCTContext.runActivity(named: "Tap Exchange action on main screen (unavailable state)") { _ in
            waitAndAssertTrue(swapActionButton, "Exchange title should exist on main screen")
            swapActionButton.tap()
            return self
        }
    }

    func tapToken(_ label: String) -> TokenScreen {
        XCTContext.runActivity(named: "Tap token with label: \(label)") { _ in
            XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")
            let token = tokenElement(named: label)
            scrollTokensListToVisible(token)
            token.waitAndTap()
            return TokenScreen(app)
        }
    }

    @discardableResult
    func skipPushNotificationsSetup() -> Self {
        XCTContext.runActivity(named: "Tap 'Later' on Push Notifications sheet") { _ in
            if app.buttons["Later"].waitForExistence(timeout: .conditional) {
                app.buttons["Later"].tap()
            }
            return self
        }
    }

    @discardableResult
    func organizeTokens() -> OrganizeTokensScreen {
        XCTContext.runActivity(named: "Open organize tokens screen") { _ in
            // Ensure tokens list is loaded first
            XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")

            // Scroll inside the tokens list — app-level swipes can grab the Markets sheet and cover the button.
            XCTAssertTrue(
                scrollTokensListToVisible(organizeTokensButton),
                "Organize tokens button should be visible after scrolling tokens list"
            )

            // Use the robust waitAndTap method instead of direct tap
            XCTAssertTrue(
                organizeTokensButton.waitAndTap(timeout: .robustUIUpdate),
                "Should successfully tap organize tokens button"
            )

            // Redesign inserts the Add & Manage chooser sheet between the entry button and Organize Tokens.
            if addAndManageOrganizeRow.waitForExistence(timeout: .conditional) {
                addAndManageOrganizeRow.waitAndTap()
            }

            return OrganizeTokensScreen(app)
        }
    }

    @discardableResult
    func verifyTokenExists(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Verify token '\(tokenName)' exists on main screen") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            let token = tokenElement(named: tokenName)
            waitAndAssertTrue(token, "Token '\(tokenName)' should exist in the list")
            return self
        }
    }

    @discardableResult
    func verifyCustomTokenIndicatorExists(for tokenName: String) -> Self {
        XCTContext.runActivity(named: "Verify custom token indicator exists for '\(tokenName)'") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            let indicator = tokensList.descendants(matching: .any)
                .matching(identifier: MainAccessibilityIdentifiers.tokenCustomIndicator(for: tokenName))
                .firstMatch
            waitAndAssertTrue(indicator, "Custom token indicator should be displayed for '\(tokenName)'")
            return self
        }
    }

    @discardableResult
    func verifyTokenNotVisible(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Verify token '\(tokenName)' is not visible on main screen") { _ in
            let token = app.staticTexts
                .matching(identifier: MainAccessibilityIdentifiers.tokenTitle)
                .matching(NSPredicate(format: "label == %@", tokenName))
                .firstMatch
            XCTAssertFalse(
                token.waitForExistence(timeout: .conditional),
                "Token '\(tokenName)' should not be visible"
            )
            return self
        }
    }

    @discardableResult
    func verifyTokenVisible(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Verify token '\(tokenName)' is visible on main screen") { _ in
            let token = app.staticTexts
                .matching(identifier: MainAccessibilityIdentifiers.tokenTitle)
                .matching(NSPredicate(format: "label == %@", tokenName))
                .firstMatch
            waitAndAssertTrue(token, "Token '\(tokenName)' should be visible")
            return self
        }
    }

    @discardableResult
    func verifyAccountVisible(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Verify account '\(accountName)' visible on main screen") { _ in
            let account = app.buttons[AccountsAccessibilityIdentifiers.expandableAccountItem(accountName: accountName)]
            waitAndAssertTrue(account, "Account '\(accountName)' should be visible on main screen")
            return self
        }
    }

    @discardableResult
    func expandAccount(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Expand account '\(accountName)'") { _ in
            let account = app.buttons[AccountsAccessibilityIdentifiers.expandableAccountItem(accountName: accountName)]
            waitAndAssertTrue(account, "Account '\(accountName)' should exist on main screen")
            account.tap()
            return self
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
            return self
        }
    }

    @discardableResult
    func waitDeveloperCardBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Wait developer card banner not exists") { _ in
            let bannerElement = app.staticTexts[MainAccessibilityIdentifiers.developerCardBanner]
            XCTAssertFalse(bannerElement.exists, "Developer card banner should not be displayed")
            return self
        }
    }

    func getTokensOrder() -> TokensOrder {
        XCTContext.runActivity(named: "Get tokens order from main screen") { _ in
            XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")

            let tokenTitleQuery = tokensList.staticTexts.matching(identifier: MainAccessibilityIdentifiers.tokenTitle)
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "count > 0"),
                object: tokenTitleQuery
            )

            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)
            XCTAssertEqual(result, .completed, "Should have token title elements available")

            let tokenTitleElements = tokenTitleQuery.allElementsBoundByIndex
            let stableElements = tokenTitleElements.filter { element in
                element.exists && !element.label.isEmpty
            }

            let sortedElements = stableElements.sorted { element1, element2 in
                let tolerance: CGFloat = 1.0
                let diff = element1.frame.minY - element2.frame.minY

                if abs(diff) < tolerance {
                    return element1.frame.minX < element2.frame.minX
                } else {
                    return diff < 0
                }
            }

            let labels = sortedElements.map { $0.label }

            if labels.isEmpty {
                let allTexts = tokensList.staticTexts.allElementsBoundByIndex.map {
                    "[\($0.identifier): '\($0.label)']"
                }.joined(separator: ", ")
                XCTFail("No token titles found. Available static texts: \(allTexts)")
            }

            // No account headers on main screen yet.
            return .mainAccount(labels)
        }
    }

    @discardableResult
    func verifyTokensOrder(_ expectedOrder: TokensOrder) -> Self {
        XCTContext.runActivity(named: "Verify tokens order on main screen") { _ in
            let actual = getTokensOrder()

            // Check accounts order
            XCTAssertEqual(
                actual.accountNames,
                expectedOrder.accountNames,
                "Accounts order on main screen doesn't match. Actual: \(actual.accountNames), Expected: \(expectedOrder.accountNames)"
            )

            // Check token order within each account
            for (index, expected) in expectedOrder.enumerated() {
                let actualTokens = actual[index].tokens
                XCTAssertEqual(
                    actualTokens,
                    expected.tokens,
                    "Tokens order for account '\(expected.account)' doesn't match. Actual: \(actualTokens), Expected: \(expected.tokens)"
                )
            }
            return self
        }
    }

    @discardableResult
    func verifyTokensOrder(_ expectedOrder: [String]) -> Self {
        verifyTokensOrder(.mainAccount(expectedOrder))
    }

    @discardableResult
    func verifyTokensOrderChanged(from previousOrder: TokensOrder) -> Self {
        XCTContext.runActivity(named: "Verify token list changed after switching cards") { _ in
            let currentOrder = getTokensOrder()
            XCTAssertNotEqual(
                currentOrder.allTokensFlat,
                previousOrder.allTokensFlat,
                "Token list should change after switching cards. Previous: \(previousOrder.allTokensFlat), Current: \(currentOrder.allTokensFlat)"
            )
            return self
        }
    }

    @discardableResult
    func swipeWalletLeft() -> Self {
        XCTContext.runActivity(named: "Swipe wallet card left (next wallet)") { _ in
            waitForMainScreenReadyForSwipe()
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.18))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.18))
            start.press(forDuration: 0.1, thenDragTo: end)
            waitAndAssertTrue(totalBalance, "Main header should exist after switching wallet")
            return self
        }
    }

    @discardableResult
    func swipeWalletRight() -> Self {
        XCTContext.runActivity(named: "Swipe wallet card right (previous wallet)") { _ in
            waitForMainScreenReadyForSwipe()
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.18))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.18))
            start.press(forDuration: 0.1, thenDragTo: end)
            waitAndAssertTrue(totalBalance, "Main header should exist after switching wallet")
            return self
        }
    }

    // MARK: - Locked Wallet

    @discardableResult
    func verifyWalletLockedNotificationExists() -> Self {
        XCTContext.runActivity(named: "Verify wallet locked notification is displayed") { _ in
            waitAndAssertTrue(walletLockedNotification, "Wallet locked notification should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyWalletLockedNotificationNotExists() -> Self {
        XCTContext.runActivity(named: "Verify wallet locked notification is NOT displayed") { _ in
            XCTAssertFalse(
                walletLockedNotification.waitForExistence(timeout: .conditional),
                "Wallet locked notification should NOT be displayed after unlocking"
            )
            return self
        }
    }

    @discardableResult
    func verifyWalletLockedNotificationHasMessage() -> Self {
        XCTContext.runActivity(named: "Verify wallet locked notification has explanatory message") { _ in
            waitAndAssertTrue(walletLockedNotification, "Wallet locked notification should be displayed")
            let message = walletLockedNotification.staticTexts[CommonUIAccessibilityIdentifiers.notificationMessage].firstMatch
            waitAndAssertTrue(message, "Wallet locked notification should contain an explanatory message")
            return self
        }
    }

    @discardableResult
    func tapWalletLockedNotification() -> Self {
        XCTContext.runActivity(named: "Tap wallet locked notification to initiate unlock") { _ in
            waitAndAssertTrue(walletLockedNotification, "Wallet locked notification should be displayed")
            walletLockedNotification.waitAndTap()
            return self
        }
    }

    @discardableResult
    func selectMockCardFromScannerAlert(name: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Select mock card from scanner alert: \(name.rawValue)") { _ in
            let walletButton = app.buttons[name.rawValue].firstMatch
            if !walletButton.isHittable {
                app.swipeUp()
            }
            walletButton.waitAndTap()
            return self
        }
    }

    // MARK: - Add Wallet

    @discardableResult
    func addNewWallet(name: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Add new wallet: \(name.rawValue)") { _ in
            openDetails()
                .tapAddNewWallet()

            let walletButton = app.buttons[name.rawValue].firstMatch
            if !walletButton.isHittable {
                app.swipeUp()
            }
            walletButton.waitAndTap()

            waitAndAssertTrue(tokensList, "Tokens list should exist after adding new wallet")
            return self
        }
    }

    @discardableResult
    func openDetails() -> DetailsScreen {
        XCTContext.runActivity(named: "Open details screen") { _ in
            detailsButton.waitAndTap()
            return DetailsScreen(app)
        }
    }

    @discardableResult
    func openTangemPay() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Open Tangem Pay from main screen") { _ in
            scrollToElement(tangemPayTile)
            tangemPayTile.waitAndTap()
            return TangemPayMainScreen(app)
        }
    }

    @discardableResult
    func longPressWalletHeader() -> Self {
        XCTContext.runActivity(named: "Long press wallet header") { _ in
            waitAndAssertTrue(headerCardImage, "Header card image should exist")
            headerCardImage.press(forDuration: 1.0)
            return self
        }
    }

    func longPressToken(_ tokenName: String) -> ContextMenuScreen {
        XCTContext.runActivity(named: "Long press token: \(tokenName)") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            let token = tokenElement(named: tokenName)
            waitAndAssertTrue(token, "Token '\(tokenName)' should exist")
            scrollTokensListToVisible(token)

            // Wait for balance to load — context menu captures content at presentation time
            let balanceElement = tokensList.staticTexts[MainAccessibilityIdentifiers.tokenBalance(for: tokenName)].firstMatch
            _ = balanceElement.waitForExistence(timeout: .robustUIUpdate)

            // Retry long press if context menu doesn't appear (can be flaky on CI)
            let contextMenuIndicator = app.buttons["Buy"].firstMatch
            let maxAttempts = 3
            for attempt in 1 ... maxAttempts {
                token.press(forDuration: 1.5)
                if contextMenuIndicator.waitForExistence(timeout: .quick) {
                    break
                }

                // Dismiss any opened context menu before retrying
                if attempt < maxAttempts {
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
                    _ = token.waitForExistence(timeout: .quick)
                    scrollTokensListToVisible(token)
                }
            }

            return ContextMenuScreen(app)
        }
    }

    @discardableResult
    func waitForNoRenameButton() -> Self {
        XCTContext.runActivity(named: "Wait for no rename button exists") { _ in
            let renameButton = app.buttons["Rename"]
            XCTAssertFalse(renameButton.exists, "Rename button should not exist in context menu")
            return self
        }
    }

    @discardableResult
    func waitForNoDeleteButton() -> Self {
        XCTContext.runActivity(named: "Wait for delete button exists") { _ in
            let deleteButton = app.buttons["Delete"]
            XCTAssertFalse(deleteButton.exists, "Delete button should not exist in context menu")
            return self
        }
    }

    @discardableResult
    func waitForDeleteButtonExists() -> Self {
        XCTContext.runActivity(named: "Wait for delete button exists") { _ in
            let deleteButton = app.buttons["Delete"]
            waitAndAssertTrue(deleteButton, "Delete button should exist in context menu")
            return self
        }
    }

    @discardableResult
    func waitForTotalBalanceDisplayedAsDash() -> Self {
        XCTContext.runActivity(named: "Wait for total balance displayed as dash") { _ in
            waitAndAssertTrue(totalBalance, "Total balance element should exist")
            XCTAssertTrue(totalBalance.label.contains("–"), "Total balance should be displayed as dash")
            return self
        }
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
            scrollTokensListToVisible(tokenElement(named: tokenName))

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
            scrollTokensListToVisible(tokenElement(named: tokenName))

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
            scrollTokensListToVisible(tokenElement(named: tokenName))

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
            return self
        }
    }

    @discardableResult
    func waitForTotalBalanceShimmer() -> Self {
        XCTContext.runActivity(named: "Wait for total balance shimmer effect") { _ in
            waitAndAssertTrue(totalBalanceShimmer, "Total balance shimmer should be displayed")
            return self
        }
    }

    @discardableResult
    func waitForTotalBalanceShimmerToDisappear() -> Self {
        XCTContext.runActivity(named: "Wait for total balance shimmer to disappear") { _ in
            XCTAssertTrue(totalBalanceShimmer.waitForNonExistence(timeout: .robustUIUpdate), "Total balance shimmer should disappear")
            return self
        }
    }

    @discardableResult
    func waitForTotalBalanceShimmerToComplete() -> Self {
        XCTContext.runActivity(named: "Wait for total balance shimmer to complete and show final content") { _ in
            // First wait for shimmer to disappear
            XCTAssertTrue(totalBalanceShimmer.waitForNonExistence(timeout: .robustUIUpdate), "Total balance shimmer should disappear")

            // Then wait for final content to appear
            waitAndAssertTrue(totalBalance, "Total balance should be displayed")
            XCTAssertFalse(totalBalance.label.isEmpty, "Total balance should have content")
            return self
        }
    }

    @discardableResult
    func waitForSynchronizeAddressesButtonExists() -> Self {
        XCTContext.runActivity(named: "Wait for synchronize addresses button exists") { _ in
            waitAndAssertTrue(missingDerivationNotification, "Missing derivation notification should exist")
            return self
        }
    }

    @discardableResult
    func verifyMissingDerivationNotificationHasMessage() -> Self {
        XCTContext.runActivity(named: "Verify missing derivation notification has explanatory message") { _ in
            waitAndAssertTrue(missingDerivationNotification, "Missing derivation notification should be displayed")
            let message = missingDerivationNotification.staticTexts[CommonUIAccessibilityIdentifiers.notificationMessage].firstMatch
            waitAndAssertTrue(message, "Missing derivation notification should contain an explanatory message")
            return self
        }
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
            return self
        }
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
            return self
        }
    }

    @discardableResult
    func openMarketsSheetWithSwipe() -> MarketsAndNewsScreen {
        XCTContext.runActivity(named: "Open markets sheet with swipe up gesture") { _ in
            waitAndAssertTrue(grabber)

            // Swipe up on the grabber view
            let startPoint = grabber.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let endPoint = startPoint.withOffset(CGVector(dx: 0, dy: -300))
            startPoint.press(forDuration: 0.2, thenDragTo: endPoint)

            return MarketsAndNewsScreen(app)
        }
    }

    @discardableResult
    func verifyIsGrouped(_ expectedState: Bool) -> Self {
        XCTContext.runActivity(named: "Verify tokens grouping state on main screen is \(expectedState)") { _ in
            _ = tokensList.waitForExistence(timeout: .robustUIUpdate)
            let actualState = isGrouped()
            XCTAssertEqual(
                actualState,
                expectedState,
                "Expected grouping state on main screen: \(expectedState), but got: \(actualState)"
            )
            return self
        }
    }

    private func tokenElement(named label: String) -> XCUIElement {
        tokensList.staticTexts
            .matching(identifier: MainAccessibilityIdentifiers.tokenTitle)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    /// Waits for main screen elements before coordinate-based wallet swipe.
    private func waitForMainScreenReadyForSwipe() {
        waitAndAssertTrue(tokensList, "Tokens list should exist before swiping wallet")
        // Loading state exposes the header via `totalBalanceShimmer` instead of `totalBalance`.
        let headerExists = totalBalance.waitForExistence(timeout: .conditional)
            || totalBalanceShimmer.waitForExistence(timeout: .conditional)
        XCTAssertTrue(headerExists, "Main header should exist before swiping wallet")
    }

    /// Scrolls inside `tokensList` (not the whole app) and pushes the row above the Markets sheet grabber when they overlap.
    @discardableResult
    private func scrollTokensListToVisible(_ element: XCUIElement, attempts: Int = 5) -> Bool {
        waitAndAssertTrue(tokensList, "Tokens list should exist before scrolling")

        for _ in 0 ..< attempts {
            if hasVisibleFrame(element) {
                let frame = element.frame
                if grabber.exists, frame.maxY > grabber.frame.minY {
                    let offset = min(frame.maxY - grabber.frame.minY + 50, app.frame.height)
                    scrollTokensList(byOffset: -offset)
                    continue
                }
                return true
            }
            scrollTokensList(byOffset: -250)
        }

        return hasVisibleFrame(element)
    }

    /// Avoids `.isHittable` because it aborts the test with "Activation point invalid" when a SwiftUI row is mid-animation.
    private func hasVisibleFrame(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        guard frame.width > 0, frame.height > 0, frame.isFinite else { return false }
        return app.frame.intersects(frame)
    }

    private func scrollTokensList(byOffset dy: CGFloat) {
        let start = tokensList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let end = start.withOffset(CGVector(dx: 0, dy: dy))
        start.press(forDuration: 0.1, thenDragTo: end)
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
    case walletLockedNotification

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
        case .walletLockedNotification:
            MainAccessibilityIdentifiers.walletLockedNotification
        }
    }
}

private extension CGRect {
    /// Stale XCUIElement snapshots can report infinite frames on slow CI simulators.
    var isFinite: Bool {
        minX.isFinite && minY.isFinite && width.isFinite && height.isFinite
    }
}

extension MainScreen {
    private func validateMainHeader(for cardType: CardMockAccessibilityIdentifiers) {
        XCTContext.runActivity(named: "Validate main header for card type: \(cardType.rawValue)") { _ in
            switch cardType {
            case .xlmBird, .v3seckp:
                break
            default:
                XCTAssertTrue(
                    totalBalance.waitForExistence(timeout: .robustUIUpdate),
                    "Main header total balance should be present for card type: \(cardType.rawValue)"
                )
            }
        }
    }
}
