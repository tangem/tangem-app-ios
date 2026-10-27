//
//  MarketsAndNewsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

final class MarketsAndNewsScreen: ScreenBase<MarketsAndNewsScreenElement> {
    private lazy var searchField = textField(.searchThroughMarketField)
    private lazy var searchFieldContainer = button(.searchThroughMarketFieldContainer)
    private lazy var addAccountBanner = app.buttons[AccountsAccessibilityIdentifiers.feedAddAccountBanner].firstMatch
    private lazy var forYouWidget = app.buttons[MainAccessibilityIdentifiers.feedForYouWidget].firstMatch
    private lazy var tangemPayBanner = app.buttons[TangemPayAccessibilityIdentifiers.feedBanner].firstMatch

    @discardableResult
    func openAddAccountTypeSelector() -> AddAccountTypeSelectorSheet {
        tapAddAccountBanner()
        return AddAccountTypeSelectorSheet(app)
    }

    @discardableResult
    func openAddAccountWalletSelector() -> AddAccountWalletSelectorSheet {
        tapAddAccountBanner()
        return AddAccountWalletSelectorSheet(app)
    }

    @discardableResult
    func openTangemPayOnboarding() -> TangemPayOnboardingScreen {
        tapTangemPayBanner()
        return TangemPayOnboardingScreen(app)
    }

    @discardableResult
    func openTangemPayKycStatusSheet() -> TangemPayKYCStatusSheet {
        tapTangemPayBanner()
        return TangemPayKYCStatusSheet(app)
    }

    @discardableResult
    func openTokenList() -> MarketsScreen {
        XCTContext.runActivity(named: "Scroll the Markets sheet to the token list") { _ in
            let defaultCategoryChip = app.buttons[
                MarketsAccessibilityIdentifiers.marketsSortOption(Constants.defaultCategory)
            ].firstMatch
            scrollToElement(defaultCategoryChip)
            waitAndAssertTrue(defaultCategoryChip, "Markets category chips should be reachable")
            return MarketsScreen(app)
        }
    }

    @discardableResult
    func searchForToken(_ tokenName: String) -> MarketsScreen {
        XCTContext.runActivity(named: "Search for token: \(tokenName)") { _ in
            tapSearchField()
            searchField.typeText(tokenName)
            searchField.typeText("\n")
            return MarketsScreen(app)
        }
    }

    @discardableResult
    func pasteIntoSearchField() -> MarketsScreen {
        XCTContext.runActivity(named: "Paste into Markets search field") { _ in
            tapSearchField()
            searchField.press(forDuration: 1.0)

            let pasteMenuItem = app.menuItems["Paste"]
            pasteMenuItem.waitAndTap()

            return MarketsScreen(app)
        }
    }

    @discardableResult
    func tapSearchFieldAndVerifyKeyboard() -> MarketsScreen {
        XCTContext.runActivity(named: "Tap Markets search field and verify keyboard") { _ in
            tapSearchField()
            waitAndAssertTrue(app.keyboards.firstMatch, "Keyboard should appear after tapping search field")
            return MarketsScreen(app)
        }
    }

    @discardableResult
    func typeInSearchField(_ text: String) -> MarketsScreen {
        XCTContext.runActivity(named: "Type in Markets search field: \(text)") { _ in
            waitAndAssertTrue(searchField, "Markets search field should exist")
            searchField.typeText(text)
            return MarketsScreen(app)
        }
    }

    @discardableResult
    func verifyMarketsSheetIsDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Markets sheet is displayed") { _ in
            waitAndAssertTrue(searchField, "Markets sheet should be displayed with search field")
            return self
        }
    }

    @discardableResult
    func verifyAddAccountBannerDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify 'Add account' banner is displayed in the feed") { _ in
            waitAndAssertTrue(addAccountBanner, "'Add account' banner should be displayed in the feed")
            return self
        }
    }

    @discardableResult
    func verifyAddAccountBannerNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify 'Add account' banner is not displayed in the feed") { _ in
            waitAndAssertTrue(forYouWidget, "Feed widgets should be rendered before checking the 'Add account' banner")
            XCTAssertTrue(
                addAccountBanner.waitForNonExistence(timeout: .robustUIUpdate),
                "'Add account' banner should not be displayed for a Note card"
            )
            return self
        }
    }

    @discardableResult
    func verifyTangemPayBannerDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify 'Tangem Pay' banner is displayed in the feed") { _ in
            waitAndAssertTrue(tangemPayBanner, timeout: .networkRequest, "'Tangem Pay' banner should be displayed in the feed")
            XCTAssertTrue(
                tangemPayBanner.label.contains(Localization.feedPromoTangemPayTitle),
                "'Tangem Pay' banner title should be displayed"
            )
            XCTAssertTrue(
                tangemPayBanner.label.contains(Localization.feedPromoTangemPayDescription),
                "'Tangem Pay' banner description should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyTangemPayBannerNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify 'Tangem Pay' banner is not displayed in the feed") { _ in
            waitAndAssertTrue(forYouWidget, "Feed widgets should be rendered before checking the 'Tangem Pay' banner")
            XCTAssertTrue(
                tangemPayBanner.staysAbsent(for: .robustUIUpdate),
                "'Tangem Pay' banner should not be displayed in the feed"
            )
            return self
        }
    }

    private func tapTangemPayBanner() {
        XCTContext.runActivity(named: "Tap 'Tangem Pay' banner in the feed") { _ in
            XCTAssertTrue(tangemPayBanner.waitAndTap(), "'Tangem Pay' banner should be tappable in the feed")
        }
    }

    private func tapAddAccountBanner() {
        XCTContext.runActivity(named: "Tap 'Add account' banner in the feed") { _ in
            addAccountBanner.waitAndTap()
        }
    }

    /// Temporary fallback to support both the legacy and redesigned Markets layouts.
    private func tapSearchField() {
        if searchFieldContainer.exists {
            searchFieldContainer.waitAndTap()
            waitAndAssertTrue(app.keyboards.firstMatch, "Keyboard should appear after tapping search container")
        } else {
            searchField.waitAndTap()
        }
    }
}

enum MarketsAndNewsScreenElement: String, UIElement {
    case searchThroughMarketField
    case searchThroughMarketFieldContainer

    var accessibilityIdentifier: String {
        switch self {
        case .searchThroughMarketField:
            return MainAccessibilityIdentifiers.searchThroughMarketField
        case .searchThroughMarketFieldContainer:
            return MainAccessibilityIdentifiers.searchThroughMarketFieldContainer
        }
    }
}

private extension MarketsAndNewsScreen {
    enum Constants {
        static let defaultCategory = "rating"
    }
}
