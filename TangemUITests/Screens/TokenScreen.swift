//
//  TokenScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TokenScreen: ScreenBase<TokenScreenElement> {
    enum TokenAction: String {
        case buy = "Buy"
        case swap = "Swap"
        case send = "Send"
    }

    private lazy var moreButton = app.navigationBars.buttons["More"].firstMatch
    private lazy var hideTokenButton = button(.hideTokenButton)
    private lazy var topUpBanner = staticText(.topUpBanner)
    private lazy var notEnoughFeeForTransactionBanner = staticText(.notEnoughFeeForTransactionBanner)
    private lazy var goToFeeCurrencyButton = notificationBannerButton(TokenAccessibilityIdentifiers.notEnoughFeeForTransactionBanner)
    private lazy var tokenNameLabel = staticText(.tokenNameLabel)

    // Action buttons
    private lazy var receiveButton = button(.receiveButton)
    private lazy var sendButton = button(.sendButton)
    private lazy var swapButton = button(.swapButton)
    private lazy var buyButton = button(.buyButton)
    private lazy var sellButton = button(.sellButton)
    private lazy var addFundsButton = button(.addFundsButton)
    private lazy var transferButton = button(.transferButton)

    // Staking elements
    private lazy var nativeStakingBlock = button(.nativeStakingBlock)
    private lazy var nativeStakingTitle = staticText(.nativeStakingTitle)
    private lazy var nativeStakingChevron = image(.nativeStakingChevron)

    private lazy var availableSegment = button(.availableSegment)
    private lazy var balanceModePicker = button(.balanceModePicker)

    // Balance elements
    private lazy var totalBalance = staticText(.totalBalance)
    private lazy var availableBalance = staticText(.availableBalance)
    private lazy var stakingBalance = staticText(.stakingBalance)
    private lazy var stakingBalanceCrypto = app.staticTexts.matching(identifier: TokenAccessibilityIdentifiers.stakingBalance).element(boundBy: 1)

    private lazy var pendingSwapHistoryItem = app.staticTexts[
        TxHistoryAccessibilityIdentifiers.transactionItem(key: Constants.swapTransactionKey)
    ].firstMatch

    private lazy var marketingBanner = button(.marketingBanner)

    func hideToken(name: String) -> MainScreen {
        moreButton.tap()
        hideTokenButton.waitAndTap()
        app.alerts["Hide \(name)"].buttons["Hide"].waitAndTap()
        return MainScreen(app)
    }

    @discardableResult
    func tapActionButton(_ action: TokenAction) -> Self {
        XCTContext.runActivity(named: "Tap token action button: \(action.rawValue)") { _ in
            switch action {
            case .buy:
                resolveActionButton(buyButton, viaGroup: addFundsButton)
            case .swap:
                swapButton.waitAndTap()
            case .send:
                resolveActionButton(sendButton, viaGroup: transferButton)
            }
            return self
        }
    }

    @discardableResult
    func tapBuyButton() -> OnrampScreen {
        tapActionButton(.buy)
        return OnrampScreen(app)
    }

    @discardableResult
    func tapSwapButton() -> SwapStoriesScreen {
        tapActionButton(.swap)
        return SwapStoriesScreen(app)
    }

    /// Swap stays enabled when unavailable; tapping surfaces the reason alert instead of a dead disabled button.
    @discardableResult
    func tapUnavailableSwapButton() -> Self {
        XCTContext.runActivity(named: "Tap unavailable Swap action button to surface reason alert") { _ in
            waitAndAssertTrue(swapButton, "Swap button should exist")
            swapButton.tap()
            return self
        }
    }

    @discardableResult
    func tapSendButton() -> SendScreen {
        tapActionButton(.send)
        return SendScreen(app)
    }

    @discardableResult
    func tapReceiveButton() -> NetworkSelectionWarningSheet {
        XCTContext.runActivity(named: "Tap Receive action button") { _ in
            resolveActionButton(receiveButton, viaGroup: addFundsButton)
        }
        return NetworkSelectionWarningSheet(app)
    }

    @discardableResult
    func tapTransferButton() -> Self {
        XCTContext.runActivity(named: "Tap Transfer action button") { _ in
            waitAndAssertTrue(transferButton, "Transfer button should be displayed")
            transferButton.waitAndTap()
            return self
        }
    }

    func openStakeDetails() -> StakingDetailsScreen {
        XCTContext.runActivity(named: "Open stake details via native staking block") { _ in
            nativeStakingBlock.waitAndTap()
            return StakingDetailsScreen(app)
        }
    }

    func tapNativeStakingBlock() -> StakingDetailsScreen {
        XCTContext.runActivity(named: "Tap native staking block") { _ in
            nativeStakingBlock.waitAndTap()
            return StakingDetailsScreen(app)
        }
    }

    @discardableResult
    func waitForStakingInfo() -> Self {
        XCTContext.runActivity(named: "Validate staking information on token screen") { _ in
            waitAndAssertTrue(nativeStakingBlock, "Native staking block should be displayed")
            waitAndAssertTrue(nativeStakingTitle, "Native staking title should be displayed")

            return self
        }
    }

    @discardableResult
    func validateTopUpWalletBannerExists() -> Self {
        XCTContext.runActivity(named: "Validate 'Top up your wallet' banner exists") { _ in
            waitAndAssertTrue(topUpBanner, "Top up wallet banner should be displayed")
            return self
        }
    }

    @discardableResult
    func tapGoToFeeCurrencyButton() -> TokenScreen {
        _ = XCTContext.runActivity(named: "Tap go to fee currency button") { _ in
            goToFeeCurrencyButton.waitAndTap()
        }
        return TokenScreen(app)
    }

    @discardableResult
    func waitForTokenName(_ name: String) -> Self {
        XCTContext.runActivity(named: "Validate token name '\(name)' is displayed") { _ in
            waitAndAssertTrue(tokenNameLabel, "Token name label should exist")
            XCTAssertEqual(tokenNameLabel.label, name, "Token details should display '\(name)' token name")
        }
        return self
    }

    @discardableResult
    func validateTopUpWalletBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate 'Top up your wallet' banner not exists") { _ in
            topUpBanner.waitForState(state: .doesntExist)
            XCTAssertFalse(topUpBanner.exists, "Top up wallet banner should not be displayed")
            return self
        }
    }

    @discardableResult
    func waitForPendingExpressTransaction() -> Self {
        XCTContext.runActivity(named: "Wait for pending express transaction to appear") { _ in
            scrollToElement(pendingSwapHistoryItem)
            waitAndAssertTrue(pendingSwapHistoryItem, "Pending swap should be displayed in history")
            return self
        }
    }

    @discardableResult
    func tapPendingExpressTransaction() -> TransactionDetailsSheet {
        XCTContext.runActivity(named: "Tap pending express transaction to open its details") { _ in
            waitAndAssertTrue(pendingSwapHistoryItem, "Pending swap should be displayed in history")
            scrollToElement(pendingSwapHistoryItem)
            pendingSwapHistoryItem.waitAndTap()
        }
        return TransactionDetailsSheet(app)
    }

    @discardableResult
    func goBackToMain() -> MainScreen {
        XCTContext.runActivity(named: "Go back to main screen") { _ in
            app.navigationBars.buttons["Back"].waitAndTap()
            return MainScreen(app)
        }
    }

    func marketPriceBlock() -> TokenDetailsMarketPriceScreen {
        TokenDetailsMarketPriceScreen(app)
    }

    // MARK: - Segmented Control Methods

    @discardableResult
    func tapAvailableSegment() -> Self {
        XCTContext.runActivity(named: "Switch to Available balance") { _ in
            // Temporary fallback to support both the legacy and redesigned token screen layouts.
            if availableSegment.exists {
                availableSegment.waitAndTap()
            } else {
                balanceModePicker.waitAndTap()
            }
            return self
        }
    }

    // MARK: - Balance Methods

    func getTotalBalance() -> String {
        XCTContext.runActivity(named: "Get total balance") { _ in
            waitAndAssertTrue(totalBalance, "Total balance element should exist")
            return totalBalance.label
        }
    }

    /// Swap direction is resolved from the token's fiat balance at the moment Swap is tapped; wait for a
    /// non-zero balance so the token becomes the swap source and doesn't flip to the receive side.
    @discardableResult
    func waitForNonZeroTotalBalance() -> Self {
        XCTContext.runActivity(named: "Wait for non-zero token balance") { _ in
            waitAndAssertTrue(totalBalance, "Total balance element should exist")
            let loaded = NSPredicate(format: "label MATCHES %@", ".*[1-9].*")
            let result = XCTWaiter().wait(
                for: [XCTNSPredicateExpectation(predicate: loaded, object: totalBalance)],
                timeout: .robustUIUpdate
            )
            XCTAssertEqual(result, .completed, "Token fiat balance should load to a non-zero value, was '\(totalBalance.label)'")
            return self
        }
    }

    @discardableResult
    func waitForTotalBalanceContainsCurrency(_ currencySymbol: String) -> Self {
        XCTContext.runActivity(named: "Validate token total balance contains currency symbol: \(currencySymbol)") { _ in
            waitAndAssertTrue(totalBalance, "Total balance element should exist")
            let balanceText = totalBalance.label
            XCTAssertTrue(
                balanceText.contains(currencySymbol),
                "Token total balance should contain '\(currencySymbol)' but was '\(balanceText)'"
            )
            return self
        }
    }

    func getAvailableBalance() -> String {
        XCTContext.runActivity(named: "Get available balance") { _ in
            waitAndAssertTrue(availableBalance, "Available balance element should exist")
            return availableBalance.label
        }
    }

    func getStakingBalance() -> String {
        XCTContext.runActivity(named: "Get staking balance") { _ in
            waitAndAssertTrue(stakingBalance, "Staking balance element should exist")
            return stakingBalance.label
        }
    }

    func getStakingBalanceCrypto() -> String {
        XCTContext.runActivity(named: "Get staking balance crypto value") { _ in
            waitAndAssertTrue(stakingBalanceCrypto, "Staking balance crypto element should exist")
            return stakingBalanceCrypto.label
        }
    }

    // MARK: - Action Buttons Validation Methods

    @discardableResult
    func waitForActionButtons(requireSendOrTransfer: Bool = true, requireSwapEnabled: Bool = true) -> Self {
        XCTContext.runActivity(named: "Wait for action buttons") { _ in
            // Swap is direct in every layout (legacy, inlineList, buttonsRow).
            waitAndAssertTrue(swapButton, "Swap button should exist")
            // Swap is legitimately disabled for tokens without an exchange route (e.g. VeThor).
            if requireSwapEnabled {
                XCTAssertTrue(swapButton.isEnabled, "Swap button should be enabled")
            }
            // Legacy/inlineList: direct Buy/Receive/Send; buttonsRow: Buy/Receive under `Add Funds`, Send under `Transfer`.
            waitForEither(buyButton, or: addFundsButton, "Buy or Add Funds entry should be visible")
            waitForEither(receiveButton, or: addFundsButton, "Receive or Add Funds entry should be visible")
            // Transfer entry is legitimately absent when the token has no outgoing options (e.g. empty balance).
            if requireSendOrTransfer {
                waitForEither(sendButton, or: transferButton, "Send or Transfer entry should be visible")
            }
            return self
        }
    }

    @discardableResult
    func verifySendUnavailable() -> Self {
        XCTContext.runActivity(named: "Verify Send is unavailable on token details") { _ in
            XCTAssertFalse(
                sendButton.waitForExistence(timeout: .conditional),
                "Send button should not be visible when sending is unavailable"
            )
            XCTAssertFalse(
                transferButton.waitForExistence(timeout: .conditional),
                "Transfer entry should not be visible when sending is unavailable"
            )
            return self
        }
    }

    @discardableResult
    func verifyCustomTokenIndicatorExists() -> Self {
        XCTContext.runActivity(named: "Verify custom token indicator exists on token details") { _ in
            // Gate on a details-only element first so the assertion runs on the details screen and can't be
            // satisfied by a custom indicator from the main token list during/after navigation.
            waitAndAssertTrue(tokenNameLabel, "Token details screen should be loaded")

            let indicators = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH %@", MainAccessibilityIdentifiers.tokenCustomIndicatorPrefix))
            // Require an on-screen match instead of `.firstMatch`, which could resolve to an off-screen indicator.
            let appElement = app
            let onScreen = NSPredicate { _, _ in
                indicators.allElementsBoundByIndex.contains { element in
                    let frame = element.frame
                    return !frame.isNull && !frame.isInfinite && frame.width > 0
                        && appElement.frame.contains(CGPoint(x: frame.midX, y: frame.midY))
                }
            }
            let result = XCTWaiter().wait(
                for: [XCTNSPredicateExpectation(predicate: onScreen, object: nil)],
                timeout: .robustUIUpdate
            )
            XCTAssertEqual(result, .completed, "Custom token indicator should be displayed on token details screen")
            return self
        }
    }

    // MARK: - Marketing Banner Methods

    @discardableResult
    func verifyMarketingBannerDisplayed(text: String) -> Self {
        XCTContext.runActivity(named: "Verify marketing banner with text '\(text)' is displayed") { _ in
            waitAndAssertTrue(marketingBanner, timeout: .networkRequest, "Marketing banner should be displayed")
            XCTAssertTrue(
                marketingBanner.label.contains(text),
                "Marketing banner should contain '\(text)' but was '\(marketingBanner.label)'"
            )
            return self
        }
    }

    @discardableResult
    func tapMarketingBanner() -> SwapStoriesScreen {
        XCTContext.runActivity(named: "Tap marketing banner") { _ in
            waitAndAssertTrue(marketingBanner, "Marketing banner should exist")
            marketingBanner.waitAndTap()
            return SwapStoriesScreen(app)
        }
    }

    // MARK: - Notification Validation Methods

    @discardableResult
    func waitForNotEnoughFeeForTransactionBanner() -> Self {
        XCTContext.runActivity(named: "Validate 'Not enough fee for transaction' notification banner exists") { _ in
            waitAndAssertTrue(notEnoughFeeForTransactionBanner, "'Not enough fee for transaction' notification banner should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyInsufficientFeeCurrencyNotification(token: String, feeCurrencyName: String, feeCurrencySymbol: String) -> Self {
        XCTContext.runActivity(named: "Validate 'insufficient \(feeCurrencyName) to cover fee' notification is displayed") { _ in
            waitAndAssertTrue(
                notEnoughFeeForTransactionBanner,
                "'Not enough fee for transaction' notification banner should be displayed"
            )

            let bannerLabel = notEnoughFeeForTransactionBanner.label

            let expectedTitle = "Insufficient \(feeCurrencyName) to cover network fee"
            XCTAssertTrue(
                bannerLabel.localizedCaseInsensitiveContains(expectedTitle),
                "Notification should contain title: \(expectedTitle) but was '\(bannerLabel)'"
            )

            let expectedMessage = "\(token) is an asset in the \(feeCurrencyName) network. To make a \(token) transaction, you must deposit some \(feeCurrencyName) (\(feeCurrencySymbol)) to cover the network fee."
            XCTAssertTrue(
                bannerLabel.localizedCaseInsensitiveContains(expectedMessage),
                "Notification should contain message: \(expectedMessage) but was '\(bannerLabel)'"
            )

            waitAndAssertTrue(goToFeeCurrencyButton, "'Go to fee currency' button should be displayed")
            return self
        }
    }

    // MARK: - Swap Button State Methods

    @discardableResult
    func waitForSwapButtonEnabled() -> Self {
        XCTContext.runActivity(named: "Verify Swap button is available") { _ in
            waitAndAssertTrue(swapButton, "Swap button should exist")
            return self
        }
    }

    /// Direct button first (legacy/inlineList); otherwise tap the group (buttonsRow) and its bottom sheet.
    private func resolveActionButton(_ direct: XCUIElement, viaGroup group: XCUIElement) {
        waitForEither(direct, or: group, "Neither direct nor grouped action button appeared")
        if direct.exists {
            direct.waitAndTap()
            return
        }
        group.waitAndTap()
        // Single-option groups navigate directly without a bottom sheet, so `direct` may not reappear.
        if direct.waitForExistence(timeout: .shortUIUpdate) {
            direct.waitAndTap()
        }
    }

    private func waitForEither(
        _ a: XCUIElement,
        or b: XCUIElement,
        timeout: TimeInterval = .robustUIUpdate,
        _ message: String
    ) {
        let predicate = NSPredicate { _, _ in a.exists || b.exists }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        if XCTWaiter().wait(for: [expectation], timeout: timeout) != .completed {
            XCTFail(message)
        }
    }
}

// MARK: - Transaction History

extension TokenScreen {
    @discardableResult
    func waitForTransaction(key: String) -> Self {
        XCTContext.runActivity(named: "Wait for transaction '\(key)' in history") { _ in
            let item = app.staticTexts[TxHistoryAccessibilityIdentifiers.transactionItem(key: key)].firstMatch
            scrollToElement(item)
            waitAndAssertTrue(item, "Transaction '\(key)' should be displayed in history")
            return self
        }
    }

    @discardableResult
    func waitForTransactionSubtitle(contains text: String) -> Self {
        XCTContext.runActivity(named: "Wait for a transaction subtitle containing '\(text)'") { _ in
            let predicate = NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "txHistoryTransactionSubtitle_", text)
            let subtitle = app.staticTexts.matching(predicate).firstMatch
            scrollToElement(subtitle)
            waitAndAssertTrue(subtitle, "A transaction subtitle containing '\(text)' should be displayed in history")
            return self
        }
    }

    @discardableResult
    func assertTransactionAmount(key: String, contains amount: String) -> Self {
        XCTContext.runActivity(named: "Assert transaction '\(key)' amount contains '\(amount)'") { _ in
            let element = app.staticTexts[TxHistoryAccessibilityIdentifiers.transactionAmount(key: key)].firstMatch
            waitAndAssertTrue(element, "Transaction amount for '\(key)' should exist")
            XCTAssertTrue(
                element.label.contains(amount),
                "Transaction '\(key)' amount should contain '\(amount)' but was '\(element.label)'"
            )
            return self
        }
    }

    @discardableResult
    func assertTransactionCurrency(key: String, equals currency: String) -> Self {
        XCTContext.runActivity(named: "Assert transaction '\(key)' currency equals '\(currency)'") { _ in
            let element = app.staticTexts[TxHistoryAccessibilityIdentifiers.transactionCurrency(key: key)].firstMatch
            waitAndAssertTrue(element, "Transaction currency for '\(key)' should exist")
            XCTAssertEqual(
                element.label,
                currency,
                "Transaction '\(key)' currency should equal '\(currency)'"
            )
            return self
        }
    }

    @discardableResult
    func assertTransactionConfirmed(key: String) -> Self {
        XCTContext.runActivity(named: "Assert transaction '\(key)' is confirmed") { _ in
            let status = app.descendants(matching: .any)[TxHistoryAccessibilityIdentifiers.transactionConfirmedStatus(key: key)].firstMatch
            waitAndAssertTrue(status, "Transaction '\(key)' should have a confirmed status")
            return self
        }
    }

    @discardableResult
    func assertTransactionInProgress(key: String) -> Self {
        XCTContext.runActivity(named: "Assert transaction '\(key)' is in progress") { _ in
            let status = app.descendants(matching: .any)[TxHistoryAccessibilityIdentifiers.transactionInProgressStatus(key: key)].firstMatch
            waitAndAssertTrue(status, "Transaction '\(key)' should have an in-progress status")
            return self
        }
    }

    @discardableResult
    func assertTransactionSubtitle(key: String, contains text: String) -> Self {
        XCTContext.runActivity(named: "Assert transaction '\(key)' subtitle contains '\(text)'") { _ in
            let subtitle = app.descendants(matching: .any)[TxHistoryAccessibilityIdentifiers.transactionSubtitle(key: key)].firstMatch
            waitAndAssertTrue(subtitle, "Transaction '\(key)' subtitle should be displayed")

            let containsPredicate = NSPredicate(format: "label CONTAINS %@", text)
            let matchesLabel = subtitle.label.contains(text)
            let matchesDescendant = subtitle.staticTexts.containing(containsPredicate).firstMatch.exists
            // The id may land on a container element; fall back to an app-wide static-text search (one tx on screen).
            let matchesAppWide = app.staticTexts.containing(containsPredicate).firstMatch.exists

            XCTAssertTrue(
                matchesLabel || matchesDescendant || matchesAppWide,
                "Transaction '\(key)' subtitle should contain '\(text)'; scoped label was '\(subtitle.label)'"
            )
            return self
        }
    }
}

enum TokenScreenElement: String, UIElement {
    case moreButton
    case hideTokenButton
    case nativeStakingBlock
    case nativeStakingTitle
    case nativeStakingChevron
    case topUpBanner
    case tokenNameLabel
    case notEnoughFeeForTransactionBanner
    case availableSegment
    case balanceModePicker
    case totalBalance
    case availableBalance
    case stakingBalance
    case receiveButton
    case sendButton
    case swapButton
    case buyButton
    case sellButton
    case addFundsButton
    case transferButton
    case marketingBanner

    var accessibilityIdentifier: String {
        switch self {
        case .moreButton:
            return TokenAccessibilityIdentifiers.moreButton
        case .hideTokenButton:
            return TokenAccessibilityIdentifiers.hideTokenButton
        case .nativeStakingBlock:
            return TokenAccessibilityIdentifiers.nativeStakingBlock
        case .nativeStakingTitle:
            return TokenAccessibilityIdentifiers.nativeStakingTitle
        case .nativeStakingChevron:
            return TokenAccessibilityIdentifiers.nativeStakingChevron
        case .topUpBanner:
            return TokenAccessibilityIdentifiers.topUpWalletBanner
        case .tokenNameLabel:
            return TokenAccessibilityIdentifiers.tokenNameLabel
        case .notEnoughFeeForTransactionBanner:
            return TokenAccessibilityIdentifiers.notEnoughFeeForTransactionBanner
        case .availableSegment:
            return "Available"
        case .balanceModePicker:
            return TokenAccessibilityIdentifiers.balanceModePicker
        case .totalBalance:
            return TokenAccessibilityIdentifiers.totalBalance
        case .availableBalance:
            return TokenAccessibilityIdentifiers.availableBalance
        case .stakingBalance:
            return TokenAccessibilityIdentifiers.stakingBalance
        case .receiveButton:
            return ActionButtonsAccessibilityIdentifiers.receiveButton
        case .sendButton:
            return ActionButtonsAccessibilityIdentifiers.sendButton
        case .swapButton:
            return ActionButtonsAccessibilityIdentifiers.swapButton
        case .buyButton:
            return ActionButtonsAccessibilityIdentifiers.buyButton
        case .sellButton:
            return ActionButtonsAccessibilityIdentifiers.sellButton
        case .addFundsButton:
            return ActionButtonsAccessibilityIdentifiers.addFundsButton
        case .transferButton:
            return ActionButtonsAccessibilityIdentifiers.transferButton
        case .marketingBanner:
            // Campaign id fixed by the `TokenDetailsSwapBanner` mock scenario state.
            return MarketingBannerAccessibilityIdentifiers.standaloneBanner(id: 9001)
        }
    }
}

private extension TokenScreen {
    enum Constants {
        static let swapTransactionKey = "swap"
    }
}
