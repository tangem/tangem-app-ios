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
    private lazy var addAndManageAddTokensRow = app.buttons[TokensManagementChooserAccessibilityIdentifiers.addTokensRow].firstMatch
    private lazy var detailsButton = button(.detailsButton)
    private lazy var actionButtonsList = otherElement(.actionButtonsList)
    private lazy var headerCardImage = image(.headerCardImage)
    private lazy var totalBalance = staticText(.totalBalance)
    private lazy var totalBalanceShimmer = otherElement(.totalBalanceShimmer)
    /// Type-agnostic: redesign exposes this as `Button`, legacy as `Other`. Drop after redesign rollout.
    private lazy var missingDerivationNotification = app.descendants(matching: .any)
        .matching(identifier: MainAccessibilityIdentifiers.missingDerivationNotification)
        .firstMatch
    private lazy var walletLockedNotification = app.descendants(matching: .any)
        .matching(identifier: MainAccessibilityIdentifiers.walletLockedNotification)
        .firstMatch
    private lazy var walletLockedNotificationUnlockButton = notificationBannerButton(MainAccessibilityIdentifiers.walletLockedNotification)
    private lazy var missingDerivationSynchronizeButton = notificationBannerButton(MainAccessibilityIdentifiers.missingDerivationNotification)
    private lazy var grabber = app.otherElements[CommonUIAccessibilityIdentifiers.grabber].firstMatch
    private lazy var shtorkaExpandButton = app.buttons[MainAccessibilityIdentifiers.shtorkaExpandButton].firstMatch
    private lazy var tangemPayTile = app.buttons[TangemPayAccessibilityIdentifiers.mainScreenTile].firstMatch
    private lazy var tangemPayTileBalance = app.staticTexts[TangemPayAccessibilityIdentifiers.mainScreenTileBalance].firstMatch
    /// Type-agnostic: a decorative image inside a button is not guaranteed to stay an `Image` element.
    private lazy var tangemPayTileCachedIcon = app.descendants(matching: .any)
        .matching(identifier: TangemPayAccessibilityIdentifiers.mainScreenTileCachedIcon)
        .firstMatch
    /// Type-agnostic: redesign and legacy notifications expose different element types.
    private lazy var getTangemPayBanner = app.descendants(matching: .any)
        .matching(identifier: TangemPayAccessibilityIdentifiers.getTangemPayBanner)
        .firstMatch
    /// The banner identifier overrides the one its buttons carry, so the CTA is told apart by its label.
    private lazy var getTangemPayBannerOpenButton = app.buttons
        .matching(identifier: TangemPayAccessibilityIdentifiers.getTangemPayBanner)
        .matching(NSPredicate(format: "label == %@", "Learn more"))
        .firstMatch
    private lazy var addTokensButton = app.buttons[MainAccessibilityIdentifiers.addTokensButton].firstMatch
    private lazy var nftEntrypointRow = app.buttons[NFTAccessibilityIdentifiers.mainEntrypointRow].firstMatch
    /// The promo banner merges its title and description into a single accessibility element, so they are
    /// matched inside that element's label rather than by identifiers of their own.
    private lazy var promoBannerTitle = elementContainingText("Discover Tangem Wallet")
    /// Only the first line: the description carries a hard line break the accessibility label may fold.
    private lazy var promoBannerBody = elementContainingText("Access 13,000+ cryptocurrencies")
    private lazy var promoBannerButton = button(.walletPromoBannerButton)

    private func elementContainingText(_ text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }

    @discardableResult
    func validate(cardType: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Validate MainPage for card type: \(cardType.rawValue)") { _ in
            validateMainHeader(for: cardType)

            switch cardType {
            case .twin, .xrpNote, .xlmBird:
                XCTAssertTrue(actionButtonsList.waitForExistence(timeout: .robustUIUpdate), "Action buttons list should exist for twin cards")
            case .wallet, .wallet2, .wallet3, .walletDemo, .wallet2Demo, .shiba, .four12, .v3seckp, .ring:
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
    func verifySingleCurrencyWalletActionButtons() -> Self {
        XCTContext.runActivity(named: "Verify Buy/Sell visible and Swap hidden for single-currency card") { _ in
            waitAndAssertTrue(detailsButton, "Main screen should be loaded")
            waitAndAssertTrue(buyActionButton, timeout: .conditional, "Buy button should be visible for S2C cards")
            waitAndAssertTrue(sellActionButton, "Sell button should be visible for S2C cards")
            XCTAssertFalse(swapActionButton.waitForExistence(timeout: .shortUIUpdate), "Swap button should be hidden for S2C cards")
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

    @discardableResult
    func verifyAddTokensButtonVisible() -> Self {
        XCTContext.runActivity(named: "Verify 'Add tokens' button is visible") { _ in
            waitAndAssertTrue(addTokensButton, "'Add tokens' button should exist")
            return self
        }
    }

    @discardableResult
    func verifyTokensListDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify main screen tokens list is displayed") { _ in
            waitAndAssertTrue(tokensList, "Main screen tokens list should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyTokensListInteractive() -> Self {
        XCTContext.runActivity(named: "Verify main screen tokens list is not covered") { _ in
            waitAndAssertTrue(tokensList, "Main screen tokens list should be displayed")
            XCTAssertTrue(tokensList.waitForState(state: .hittable, for: .conditional), "Main screen tokens list should not be covered by another screen")
            return self
        }
    }

    @discardableResult
    func verifyMarketsSheetIsCollapsedOnMain() -> Self {
        XCTContext.runActivity(named: "Verify collapsed 'Markets' sheet is visible on main") { _ in
            let sheet = shtorkaExpandButton.waitForExistence(timeout: .conditional) ? shtorkaExpandButton : grabber
            waitAndAssertTrue(sheet, "Collapsed 'Markets' sheet should be visible")
            return self
        }
    }

    @discardableResult
    func verifyPromoBannerTitleVisible() -> Self {
        XCTContext.runActivity(named: "Verify 'Discover Tangem Wallet' banner title is visible") { _ in
            waitAndAssertTrue(promoBannerTitle, "'Discover Tangem Wallet' banner title should be visible")
            return self
        }
    }

    @discardableResult
    func verifyPromoBannerBodyVisible() -> Self {
        XCTContext.runActivity(named: "Verify 'Discover Tangem Wallet' banner body is visible") { _ in
            waitAndAssertTrue(promoBannerBody, "'Discover Tangem Wallet' banner body should be visible")
            return self
        }
    }

    @discardableResult
    func verifyPromoBannerTitleIsNotVisible() -> Self {
        XCTContext.runActivity(named: "Verify 'Discover Tangem Wallet' banner title is not visible") { _ in
            XCTAssertFalse(
                promoBannerTitle.waitForExistence(timeout: .conditional),
                "Promo banner should NOT be visible"
            )
            return self
        }
    }

    @discardableResult
    func tapPromoBannerButton() -> Self {
        XCTContext.runActivity(named: "Tap 'Get now with 10% off' button") { _ in
            promoBannerButton.waitAndTap()
            return self
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
            // Single-currency cards have no `tokensList`; `detailsButton` is present on every main screen.
            waitAndAssertTrue(detailsButton, "Main screen should be loaded")
            // The button sits at the bottom of the scroll, so reach it before asserting absence to avoid a false pass.
            scrollMainToBottom()
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
            tapMainActionButton(MainAccessibilityIdentifiers.buyTitle)
            return BuyTokenSelectorScreen(app)
        }
    }

    @discardableResult
    func tapMainSwap() -> SwapStoriesScreen {
        XCTContext.runActivity(named: "Tap Exchange action on main screen") { _ in
            tapMainActionButton(MainAccessibilityIdentifiers.exchangeTitle)
            return SwapStoriesScreen(app)
        }
    }

    @discardableResult
    func tapMainSell() -> SellTokenSelectorScreen {
        XCTContext.runActivity(named: "Tap Sell action on main screen") { _ in
            tapMainActionButton(MainAccessibilityIdentifiers.sellTitle)
            return SellTokenSelectorScreen(app)
        }
    }

    @discardableResult
    func tapMainBuyWhenUnavailable() -> Self {
        XCTContext.runActivity(named: "Tap Buy action on main screen (unavailable state)") { _ in
            tapUnavailableActionButton(MainAccessibilityIdentifiers.buyTitle, actionName: "Buy")
            return self
        }
    }

    @discardableResult
    func tapMainSwapWhenUnavailable() -> Self {
        XCTContext.runActivity(named: "Tap Exchange action on main screen (unavailable state)") { _ in
            tapUnavailableActionButton(MainAccessibilityIdentifiers.exchangeTitle, actionName: "Exchange")
            return self
        }
    }

    func tapToken(_ label: String) -> TokenScreen {
        XCTContext.runActivity(named: "Tap token with label: \(label)") { _ in
            XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")
            let token = tokenElement(named: label)
            XCTAssertTrue(scrollTokensListToVisible(token), "Token \(label) should be visible after scrolling")
            token.waitForStableFrame()

            // Scroll the row clear of the Markets sheet so the tap lands on it, not the sheet.
            for _ in 0 ..< 5 where !token.isHittable {
                scrollTokensList(byOffset: -200)
                token.waitForStableFrame()
            }

            token.tapEvenIfNotHittable()
            return TokenScreen(app)
        }
    }

    @discardableResult
    func skipPushNotificationsSetup() -> Self {
        XCTContext.runActivity(named: "Tap 'Later' on Push Notifications sheet") { _ in
            let laterButton = app.buttons[PushPermissionAccessibilityIdentifiers.laterButton]
            if laterButton.waitForExistence(timeout: .conditional) {
                laterButton.tap()
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

    /// Opens Add & Manage and picks "Add tokens". Only a wallet with several accounts lands on the account picker.
    @discardableResult
    func openAddTokensAccountPicker() -> AccountSelectorSheet {
        XCTContext.runActivity(named: "Open 'Add tokens' from the Add & Manage sheet") { _ in
            // Scroll inside the tokens list — app-level swipes can grab the Markets sheet and cover the button.
            XCTAssertTrue(
                scrollTokensListToVisible(organizeTokensButton),
                "Add & Manage button should be visible after scrolling tokens list; it is only rendered once an account holds at least two tokens"
            )
            XCTAssertTrue(
                organizeTokensButton.waitAndTap(timeout: .robustUIUpdate),
                "Should successfully tap Add & Manage button"
            )

            waitAndAssertTrue(addAndManageAddTokensRow, "'Add tokens' row should be shown in the Add & Manage sheet")
            addAndManageAddTokensRow.waitAndTap()

            return AccountSelectorSheet(app)
        }
    }

    @discardableResult
    func verifyTokenExists(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Verify token '\(tokenName)' exists on main screen") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            let token = tokenElement(named: tokenName)
            XCTAssertTrue(scrollTokensListToVisible(token), "Token '\(tokenName)' should be visible after scrolling")
            return self
        }
    }

    @discardableResult
    func verifyCustomTokenIndicatorExists(for tokenName: String) -> Self {
        XCTContext.runActivity(named: "Verify custom token indicator exists for '\(tokenName)'") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            let token = tokenElement(named: tokenName)
            XCTAssertTrue(scrollTokensListToVisible(token), "Token '\(tokenName)' should be visible after scrolling")
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
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            let token = tokenElement(named: tokenName)
            XCTAssertFalse(
                scrollTokensListToVisible(token),
                "Token '\(tokenName)' should not be present in the tokens list"
            )
            return self
        }
    }

    @discardableResult
    func verifyTokenVisible(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Verify token '\(tokenName)' is visible on main screen") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            let token = tokenElement(named: tokenName)
            XCTAssertTrue(
                scrollTokensListToVisible(token),
                "Token '\(tokenName)' should be visible after scrolling the tokens list"
            )
            return self
        }
    }

    @discardableResult
    func verifyAccountVisible(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Verify account '\(accountName)' visible on main screen") { _ in
            waitAndAssertTrue(accountElement(named: accountName), "Account '\(accountName)' should be visible on main screen")
            return self
        }
    }

    @discardableResult
    func expandAccount(_ accountName: String) -> Self {
        XCTContext.runActivity(named: "Expand account '\(accountName)'") { _ in
            let account = accountElement(named: accountName)
            waitAndAssertTrue(account, "Account '\(accountName)' should exist on main screen")
            account.tapEvenIfNotHittable()
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

    @discardableResult
    func verifyTokenCount(_ expectedCount: Int) -> Self {
        XCTContext.runActivity(named: "Verify token count equals \(expectedCount)") { _ in
            waitAndAssertTrue(detailsButton, "Main screen should be loaded")
            // Multi-currency renders rows inside the on-screen `tokensList`; count there so titles from other
            // wallet pages the redesign keeps mounted don't inflate the total. Single-currency has no such
            // container (a single page is mounted), so fall back to app scope.
            let scope: XCUIElement = tokensList.waitForExistence(timeout: .conditional) ? visibleTokensList() : app
            let tokenTitles = scope.staticTexts.matching(identifier: MainAccessibilityIdentifiers.tokenTitle)
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "count == %d", expectedCount),
                object: tokenTitles
            )
            let result = XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate)
            XCTAssertEqual(
                result,
                .completed,
                "Expected \(expectedCount) token(s) on main screen, found \(tokenTitles.count)"
            )
            return self
        }
    }

    func getTokensOrder() -> TokensOrder {
        XCTContext.runActivity(named: "Get tokens order from main screen") { _ in
            XCTAssertTrue(tokensList.waitForExistence(timeout: .robustUIUpdate), "Tokens list should exist")

            let visibleList = visibleTokensList()
            let tokenTitleQuery = visibleList.staticTexts.matching(identifier: MainAccessibilityIdentifiers.tokenTitle)
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
                let allTexts = visibleList.staticTexts.allElementsBoundByIndex.map {
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
            XCTAssertFalse(
                walletLockedNotification.label.isEmpty,
                "Wallet locked notification should contain an explanatory message"
            )
            return self
        }
    }

    @discardableResult
    func tapWalletLockedNotification() -> Self {
        XCTContext.runActivity(named: "Tap Unlock on the wallet locked notification") { _ in
            waitAndAssertTrue(walletLockedNotificationUnlockButton, "Unlock button should be displayed")
            walletLockedNotificationUnlockButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func selectMockCardFromScannerAlert(name: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Select mock card from scanner alert: \(name.rawValue)") { _ in
            let walletButton = app.buttons[name.rawValue].firstMatch
            guard walletButton.waitForExistence(timeout: .robustUIUpdate) else {
                XCTFail("Mock card button '\(name.rawValue)' not found in scanner alert")
                return self
            }

            scrollActionSheetToElement(walletButton)
            walletButton.waitAndTap()
            return self
        }
    }

    // MARK: - Add Wallet

    @discardableResult
    func addNewWallet(name: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Add new wallet: \(name.rawValue)") { _ in
            // Details routes through the wallet type selector while mobileWalletMultiCreation is closed.
            openDetails()
                .tapAddNewWallet()
                .tapHardwareWallet()

            selectMockCardFromScannerAlert(name: name)

            waitAndAssertTrue(tokensList, "Tokens list should exist after adding new wallet")
            return self
        }
    }

    @discardableResult
    func addNewSingleCurrencyWallet(name: CardMockAccessibilityIdentifiers, walletName: String) -> Self {
        XCTContext.runActivity(named: "Add new single-currency wallet: \(name.rawValue)") { _ in
            openDetails()
                .tapAddNewWallet()
                .tapHardwareWallet()

            selectMockCardFromScannerAlert(name: name)

            let header = app.staticTexts[walletName].firstMatch
            waitAndAssertTrue(header, "Single-currency wallet '\(walletName)' should be selected after adding")
            return self
        }
    }

    @discardableResult
    func forgetWallet(_ name: String) -> DetailsScreen {
        XCTContext.runActivity(named: "Forget wallet \(name)") { _ in
            openDetails()
                .openWalletSettings(for: name)
                .forgetWallet()
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
    func verifyTangemPayTileVisible() -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile is visible on main screen") { _ in
            scrollToElement(tangemPayTile)
            waitAndAssertTrue(tangemPayTile, "Tangem Pay tile should be visible on main screen")
            return self
        }
    }

    @discardableResult
    func openTangemPay() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Open Tangem Pay from main screen") { _ in
            tapTangemPayTile()
            return TangemPayMainScreen(app)
        }
    }

    @discardableResult
    func openTangemPaySelectPlan() -> TangemPaySelectPlanScreen {
        XCTContext.runActivity(named: "Open Tangem Pay plan selection from main screen") { _ in
            tapTangemPayTile()
            return TangemPaySelectPlanScreen(app)
        }
    }

    @discardableResult
    func openNFT() -> NFTCollectionsScreen {
        XCTContext.runActivity(named: "Open NFT collections from main screen") { _ in
            waitAndAssertTrue(nftEntrypointRow, "NFT row should be displayed on main screen")
            XCTAssertTrue(scrollTokensListToVisible(nftEntrypointRow), "NFT row should be visible after scrolling")
            nftEntrypointRow.waitAndTap()
            return NFTCollectionsScreen(app)
        }
    }

    @discardableResult
    func verifyTangemPayTileBalanceContains(_ expectedSubstring: String) -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile balance contains '\(expectedSubstring)'") { _ in
            scrollToElement(tangemPayTile)
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", expectedSubstring)
            let match = app.staticTexts
                .matching(identifier: TangemPayAccessibilityIdentifiers.mainScreenTileBalance)
                .matching(predicate)
                .firstMatch
            XCTAssertTrue(
                match.waitForExistence(timeout: .networkRequest),
                "Tangem Pay tile balance should contain '\(expectedSubstring)'. Actual: '\(tangemPayTileBalance.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyTangemPayTileSubtitle(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile subtitle contains '\(expected)'") { _ in
            scrollToElement(tangemPayTile)
            // The tile is a button and may fold its texts into a single label, so both the subtitle and the tile are matched.
            let predicate = NSPredicate(
                format: "(identifier == %@ OR identifier == %@) AND label CONTAINS[c] %@",
                TangemPayAccessibilityIdentifiers.mainScreenTileSubtitle,
                TangemPayAccessibilityIdentifiers.mainScreenTile,
                expected
            )
            waitAndAssertTrue(
                app.descendants(matching: .any).matching(predicate).firstMatch,
                timeout: .networkRequest,
                "Tangem Pay tile subtitle should contain '\(expected)'. Actual tile label: '\(tangemPayTile.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyTangemPayTileCurrency(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile shows currency '\(expected)'") { _ in
            scrollToElement(tangemPayTile)
            // The tile is a button and may fold its texts into a single label, so both the currency and the tile are matched.
            let predicate = NSPredicate(
                format: "(identifier == %@ OR identifier == %@) AND label CONTAINS %@",
                TangemPayAccessibilityIdentifiers.mainScreenTileCurrency,
                TangemPayAccessibilityIdentifiers.mainScreenTile,
                expected
            )
            waitAndAssertTrue(
                app.descendants(matching: .any).matching(predicate).firstMatch,
                timeout: .networkRequest,
                "Tangem Pay tile should show currency '\(expected)'. Actual tile label: '\(tangemPayTile.label)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyGetTangemPayBannerExists() -> Self {
        XCTContext.runActivity(named: "Verify Get Tangem Pay banner is displayed") { _ in
            waitAndAssertTrue(getTangemPayBanner, timeout: .networkRequest, "Get Tangem Pay banner should be displayed on main screen")
            return self
        }
    }

    func tapGetTangemPayBanner() -> TangemPayOnboardingScreen {
        XCTContext.runActivity(named: "Tap Get Tangem Pay banner CTA") { _ in
            waitAndAssertTrue(getTangemPayBanner, timeout: .networkRequest, "Get Tangem Pay banner should be displayed on main screen")
            getTangemPayBannerOpenButton.waitAndTap()
            return TangemPayOnboardingScreen(app)
        }
    }

    @discardableResult
    func verifyTangemPayTileExists() -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile is displayed on main screen") { _ in
            scrollToElement(tangemPayTile)
            waitAndAssertTrue(tangemPayTile, timeout: .networkRequest, "Tangem Pay tile should be displayed on main screen")
            return self
        }
    }

    @discardableResult
    func verifyTangemPayTileCachedIcon() -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile shows the cached data icon") { _ in
            scrollToElement(tangemPayTile)
            waitAndAssertTrue(tangemPayTileCachedIcon, timeout: .networkRequest, "Tangem Pay tile should show the cached data icon")
            return self
        }
    }

    @discardableResult
    func verifyTangemPayTileSubtitle(contains expectedSubstring: String) -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile subtitle contains '\(expectedSubstring)'") { _ in
            scrollToElement(tangemPayTile)
            let subtitle = tangemPayTile.staticTexts
                .matching(NSPredicate(format: "label CONTAINS[c] %@", expectedSubstring))
                .firstMatch
            waitAndAssertTrue(subtitle, timeout: .networkRequest, "Tangem Pay tile subtitle should contain '\(expectedSubstring)'")
            return self
        }
    }

    @discardableResult
    func verifyVisibleTangemPayTile(subtitle: String, balance: String) -> Self {
        XCTContext.runActivity(named: "Verify visible Tangem Pay tile shows '\(subtitle)' and balance '\(balance)'") { _ in
            let tile = visibleTangemPayTile(subtitle: subtitle)
            let balanceText = tile.staticTexts
                .matching(identifier: TangemPayAccessibilityIdentifiers.mainScreenTileBalance)
                .matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, balance))
                .firstMatch
            waitAndAssertTrue(balanceText, timeout: .networkRequest, "Visible Tangem Pay tile should show balance '\(balance)'")
            return self
        }
    }

    func openVisibleTangemPay(subtitle: String) -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Open Tangem Pay from the visible tile showing '\(subtitle)'") { _ in
            visibleTangemPayTile(subtitle: subtitle).waitAndTap()
            return TangemPayMainScreen(app)
        }
    }

    @discardableResult
    func verifyTangemPayTileSubtitle(doesNotContain unexpectedSubstring: String) -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile subtitle does not contain '\(unexpectedSubstring)'") { _ in
            scrollToElement(tangemPayTile)
            waitAndAssertTrue(tangemPayTile, timeout: .networkRequest, "Tangem Pay tile should be displayed on main screen")
            let subtitle = tangemPayTile.staticTexts
                .matching(NSPredicate(format: "label CONTAINS[c] %@", unexpectedSubstring))
                .firstMatch
            XCTAssertTrue(
                subtitle.staysAbsent(for: .conditional),
                "Tangem Pay tile subtitle should not contain '\(unexpectedSubstring)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyTangemPayTileNotVisible() -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile is not displayed on main screen") { _ in
            // The tile is absent from the start here, so the main screen has to be rendered before asserting.
            waitAndAssertTrue(tokensList, "Main screen should be displayed")
            XCTAssertTrue(
                tangemPayTile.waitForNonExistence(timeout: .conditional),
                "Tangem Pay tile should not be displayed after the account is removed"
            )
            return self
        }
    }

    @discardableResult
    func verifyTangemPayTileHasNoBalance() -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay tile shows no balance") { _ in
            scrollToElement(tangemPayTile)
            XCTAssertTrue(
                tangemPayTileBalance.waitForNonExistence(timeout: .conditional),
                "Tangem Pay tile should not show a balance when there is no cached data"
            )
            return self
        }
    }

    @discardableResult
    func verifyTangemPayTileShowsKycInProgress() -> Self {
        verifyTangemPayTileSubtitle(contains: "Verification in progress")
    }

    func openTangemPayKycStatusSheet() -> TangemPayKYCStatusSheet {
        XCTContext.runActivity(named: "Open KYC status sheet from Tangem Pay tile") { _ in
            scrollToElement(tangemPayTile)
            tangemPayTile.waitAndTap()
            return TangemPayKYCStatusSheet(app)
        }
    }

    @discardableResult
    func verifyTangemPayTileShowsKycRejected() -> Self {
        verifyTangemPayTileSubtitle(contains: "Verification rejected")
    }

    func openTangemPayKycDeclinedSheet() -> TangemPayKYCDeclinedSheet {
        XCTContext.runActivity(named: "Open KYC rejected sheet from Tangem Pay tile") { _ in
            scrollToElement(tangemPayTile)
            tangemPayTile.waitAndTap()
            return TangemPayKYCDeclinedSheet(app)
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

            // Context menu snapshots content at open time; a still-loading balance hides Send, so wait for the value.
            let balanceElement = tokensList.staticTexts[MainAccessibilityIdentifiers.tokenBalance(for: tokenName)].firstMatch
            if balanceElement.waitForExistence(timeout: .robustUIUpdate) {
                let loaded = NSPredicate { object, _ in
                    guard let element = object as? XCUIElement, element.exists else { return false }
                    return element.label.contains(where: \.isNumber)
                }
                _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: loaded, object: balanceElement)], timeout: .robustUIUpdate)
            }

            // Retry long press if context menu doesn't appear (can be flaky on CI)
            let contextMenuIndicator = app.buttons["Buy"].firstMatch
            let maxAttempts = 3
            for attempt in 1 ... maxAttempts {
                token.pressEvenIfNotHittable(forDuration: 1.5)
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

    func openTokenContextMenu(_ tokenName: String) -> ContextMenuScreen {
        XCTContext.runActivity(named: "Open context menu for token: \(tokenName)") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            let token = tokenElement(named: tokenName)
            waitAndAssertTrue(token, "Token '\(tokenName)' should exist")
            scrollTokensListToVisible(token)
            token.pressEvenIfNotHittable(forDuration: 1.5)
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

    @discardableResult
    func waitForTokenBalance(tokenName: String, toEqual expectedBalance: String) -> Self {
        XCTContext.runActivity(named: "Wait for '\(tokenName)' balance to be '\(expectedBalance)'") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            scrollTokensListToVisible(tokenElement(named: tokenName))
            let balance = tokensList.staticTexts
                .matching(identifier: MainAccessibilityIdentifiers.tokenBalance(for: tokenName))
                .matching(NSPredicate(format: "label == %@", expectedBalance))
                .firstMatch
            waitAndAssertTrue(balance, timeout: .networkRequest, "'\(tokenName)' balance should be '\(expectedBalance)'")
            return self
        }
    }

    @discardableResult
    func waitForTokenBalanceLoaded(tokenName: String) -> Self {
        XCTContext.runActivity(named: "Wait for '\(tokenName)' balance to be loaded") { _ in
            waitAndAssertTrue(tokensList, "Tokens list should exist")
            scrollTokensListToVisible(tokenElement(named: tokenName))
            let balance = tokensList.staticTexts
                .matching(identifier: MainAccessibilityIdentifiers.tokenBalance(for: tokenName))
                .matching(NSPredicate(format: "label MATCHES %@", ".*[1-9].*"))
                .firstMatch
            waitAndAssertTrue(balance, timeout: .networkRequest, "'\(tokenName)' balance should be loaded and non-zero")
            return self
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
            // Balance shows a dash briefly after a currency change, so wait for the symbol.
            let predicate = NSPredicate(format: "label CONTAINS %@", currencySymbol)
            let result = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: totalBalance)], timeout: .robustUIUpdate)
            XCTAssertEqual(result, .completed, "Total balance should contain '\(currencySymbol)' but was '\(totalBalance.label)'")
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

    /// Mobile wallets derive locally, so generating resolves the missing address without a card scan.
    @discardableResult
    func generateMissingAddressesIfNeeded() -> Self {
        XCTContext.runActivity(named: "Generate missing addresses if the notification is shown") { _ in
            guard missingDerivationNotification.waitForExistence(timeout: .conditional) else {
                return self
            }
            waitAndAssertTrue(missingDerivationSynchronizeButton, "Synchronize addresses button should be displayed")
            missingDerivationSynchronizeButton.waitAndTap()
            XCTAssertTrue(
                missingDerivationNotification.waitForNonExistence(timeout: .networkRequest),
                "Missing derivation notification should disappear after addresses are generated"
            )
            return self
        }
    }

    @discardableResult
    func verifyMissingDerivationNotificationHasMessage() -> Self {
        XCTContext.runActivity(named: "Verify missing derivation notification has explanatory message") { _ in
            waitAndAssertTrue(missingDerivationNotification, "Missing derivation notification should be displayed")
            XCTAssertFalse(
                missingDerivationNotification.label.isEmpty,
                "Missing derivation notification should contain an explanatory message"
            )
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
    func openMarketsSheet() -> MarketsAndNewsScreen {
        XCTContext.runActivity(named: "Open markets sheet") { _ in
            if shtorkaExpandButton.waitForExistence(timeout: .conditional) {
                shtorkaExpandButton.waitAndTap()
                return MarketsAndNewsScreen(app)
            }

            waitAndAssertTrue(grabber)

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
        visibleTokensList().staticTexts
            .matching(identifier: MainAccessibilityIdentifiers.tokenTitle)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    /// Redesigned main account headers share `mainTokensList`; locate by the account-name label at app scope.
    private func accountElement(named accountName: String) -> XCUIElement {
        app.staticTextByLabel(label: accountName)
    }

    /// Waits for main screen elements before coordinate-based wallet swipe.
    private func waitForMainScreenReadyForSwipe() {
        waitAndAssertTrue(tokensList, "Tokens list should exist before swiping wallet")
        // The redesigned header collapses into the navbar when the list is scrolled, so scroll back up to restore it.
        for _ in 0 ..< 5 where !totalBalance.exists && !totalBalanceShimmer.exists {
            scrollTokensList(byOffset: 250)
        }
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
                let sheetTop = marketsSheetTop
                if frame.maxY > sheetTop {
                    let offset = min(frame.maxY - sheetTop + 50, app.frame.height)
                    scrollTokensList(byOffset: -offset)
                    continue
                }
                return true
            }
            scrollTokensList(byOffset: -250)
        }

        return hasVisibleFrame(element)
    }

    private var marketsSheetTop: CGFloat {
        if shtorkaExpandButton.exists {
            return shtorkaExpandButton.frame.minY - Constants.shtorkaSearchBarInset
        }

        if grabber.exists {
            return grabber.frame.minY
        }

        return app.frame.maxY
    }

    /// Avoids `.isHittable` because it aborts the test with "Activation point invalid" when a SwiftUI row is mid-animation.
    private func hasVisibleFrame(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        guard frame.width > 0, frame.height > 0, frame.isFinite else { return false }
        return app.frame.intersects(frame)
    }

    private func scrollTokensList(byOffset dy: CGFloat) {
        // Dragging from the list container (or bare app coordinates) can land the touch on the Markets
        // sheet peeking at the bottom, which pulls the sheet open and hides every token. Anchor on a real
        // visible token row so the list's scroll view captures the gesture, and keep both endpoints above the grabber.
        let screen = app.frame
        let sheetTop = marketsSheetTop
        let rows = visibleTokenRows(above: sheetTop)

        let anchorX: CGFloat
        let startY: CGFloat
        if dy < 0, let row = rows.last {
            anchorX = row.frame.midX
            startY = row.frame.midY
        } else if dy > 0, let row = rows.first {
            anchorX = row.frame.midX
            startY = row.frame.midY
        } else {
            anchorX = screen.midX
            startY = min(screen.midY, sheetTop - 100)
        }

        let endY = min(max(startY + dy, screen.minY + 100), sheetTop - 20)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: anchorX, dy: startY))
        let end = origin.withOffset(CGVector(dx: anchorX, dy: endY))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    /// Visible token rows above the Markets grabber, top-to-bottom, used as safe drag anchors.
    private func visibleTokenRows(above sheetTop: CGFloat) -> [XCUIElement] {
        visibleTokensList().staticTexts
            .matching(identifier: MainAccessibilityIdentifiers.tokenTitle)
            .allElementsBoundByIndex
            .filter { hasVisibleFrame($0) && $0.frame.maxY < sheetTop }
            .sorted { $0.frame.minY < $1.frame.minY }
    }

    /// Horizontal paging keeps neighbor wallet pages mounted, so read tokens from the on-screen page's list, not firstMatch.
    private func visibleTokensList() -> XCUIElement {
        let query = app.otherElements.matching(identifier: MainAccessibilityIdentifiers.tokensList)
        let onScreen = query.allElementsBoundByIndex.first { element in
            let frame = element.frame
            return frame.isFinite && frame.width > 0 && app.frame.contains(CGPoint(x: frame.midX, y: frame.midY))
        }
        return onScreen ?? query.firstMatch
    }

    /// Redesign keeps every wallet page mounted (horizontal paging); with multiple wallets the same
    /// action button exists per wallet, so tap the enabled one and force the tap.
    private func tapMainActionButton(_ identifier: String) {
        // The identifier is carried by the icon button; tapping the text label does not reach it in the
        // multi-wallet carousel. Among the per-wallet buttons, prefer the visible page's enabled one
        // (isHittable is unreliable inside the carousel, so use hasVisibleFrame), then any enabled one.
        let buttonQuery = app.buttons.matching(identifier: identifier)
        let predicate = NSPredicate { _, _ in buttonQuery.allElementsBoundByIndex.contains { $0.isEnabled } }
        XCTAssertEqual(
            XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: .robustUIUpdate),
            .completed,
            "Action button '\(identifier)' should become enabled on the visible page"
        )
        let enabledButtons = buttonQuery.allElementsBoundByIndex.filter { $0.isEnabled }
        let element = enabledButtons.first { hasVisibleFrame($0) } ?? enabledButtons.first ?? buttonQuery.firstMatch
        element.tapEvenIfNotHittable()
    }

    /// Restricted button is disabled and carries the id on the Button (not the text); force-tap the visible one and retry until the tap-while-disabled gesture surfaces the alert.
    private func tapUnavailableActionButton(_ identifier: String, actionName: String) {
        let buttonQuery = app.buttons.matching(identifier: identifier)
        let alert = app.alerts.firstMatch
        XCTAssertTrue(
            buttonQuery.firstMatch.waitForExistence(timeout: .robustUIUpdate),
            "\(actionName) action button should exist on main screen"
        )
        let deadline = Date().addingTimeInterval(.robustUIUpdate)
        repeat {
            let buttons = buttonQuery.allElementsBoundByIndex
            let element = buttons.first { hasVisibleFrame($0) } ?? buttons.first ?? buttonQuery.firstMatch
            element.tapEvenIfNotHittable()
            if alert.waitForExistence(timeout: .conditional) {
                return
            }
        } while Date() < deadline
        XCTFail("\(actionName) unavailable alert did not appear after retrying taps")
    }

    /// Scrolls the main screen toward the bottom, staying above the Markets grabber so the swipe doesn't pull the sheet open.
    private func scrollMainToBottom(attempts: Int = 2) {
        let screen = app.frame
        let origin = app.coordinate(withNormalizedOffset: .zero)
        for _ in 0 ..< attempts {
            let startY = min(screen.midY, marketsSheetTop - 40)
            let endY = max(screen.minY + 120, startY - 250)
            origin.withOffset(CGVector(dx: screen.midX, dy: startY))
                .press(forDuration: 0.1, thenDragTo: origin.withOffset(CGVector(dx: screen.midX, dy: endY)))
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

    private func visibleTangemPayTile(subtitle: String) -> XCUIElement {
        let tile = app.buttons
            .matching(identifier: TangemPayAccessibilityIdentifiers.mainScreenTile)
            .containing(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, subtitle))
            .firstMatch
        waitAndAssertTrue(tile, timeout: .networkRequest, "Tangem Pay tile showing '\(subtitle)' should exist")
        scrollToElement(tile)
        XCTAssertTrue(tile.waitForState(state: .hittable), "Tangem Pay tile showing '\(subtitle)' should be on the visible wallet page")
        return tile
    }

    private func tapTangemPayTile() {
        scrollToElement(tangemPayTile)
        tangemPayTile.waitAndTap()
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
    case walletPromoBannerButton

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
        case .walletPromoBannerButton:
            MainAccessibilityIdentifiers.walletPromoBannerButton
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

private extension MainScreen {
    enum Constants {
        static let shtorkaSearchBarInset: CGFloat = 16
    }
}
