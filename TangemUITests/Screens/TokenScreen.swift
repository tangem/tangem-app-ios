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
    private lazy var notEnoughFeeForTransactionBanner = otherElement(.notEnoughFeeForTransactionBanner)
    private lazy var goToFeeCurrencyButton = button(.feeCurrencyNavigationButton)
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

    /// Pending express transaction
    private lazy var pendingExpressTransaction = button(.pendingExpressTransaction)

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
        XCTContext.runActivity(named: "Tap go to fee currency button") { _ in
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
            waitAndAssertTrue(pendingExpressTransaction, "Pending express transaction should be displayed")
            return self
        }
    }

    @discardableResult
    func goBackToMain() -> MainScreen {
        XCTContext.runActivity(named: "Go back to main screen") { _ in
            app.navigationBars.buttons["Back"].waitAndTap()
            return MainScreen(app)
        }
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

    // MARK: - Action Buttons Validation Methods

    @discardableResult
    func waitForActionButtons(requireSendOrTransfer: Bool = true) -> Self {
        XCTContext.runActivity(named: "Wait for action buttons") { _ in
            // Swap is direct in every layout (legacy, inlineList, buttonsRow).
            waitAndAssertTrue(swapButton, "Swap button should exist")
            XCTAssertTrue(swapButton.isEnabled, "Swap button should be enabled")
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

    // MARK: - Notification Validation Methods

    @discardableResult
    func waitForNotEnoughFeeForTransactionBanner() -> Self {
        XCTContext.runActivity(named: "Validate 'Not enough fee for transaction' notification banner exists") { _ in
            waitAndAssertTrue(notEnoughFeeForTransactionBanner, "'Not enough fee for transaction' notification banner should be displayed")
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

    @discardableResult
    func waitForSwapButtonDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Swap button shows unavailability alert on tap") { _ in
            waitAndAssertTrue(swapButton, "Swap button should exist")
            swapButton.waitAndTap()

            // An alert should appear indicating swap is not available
            let alert = app.alerts.firstMatch
            XCTAssertTrue(alert.waitForExistence(timeout: .robustUIUpdate), "Unavailability alert should appear for a non-swappable token")

            // Dismiss the alert
            let okButton = alert.buttons.firstMatch
            XCTAssertTrue(okButton.exists, "Alert should have a dismiss button")
            okButton.tap()
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

enum TokenScreenElement: String, UIElement {
    case moreButton
    case hideTokenButton
    case nativeStakingBlock
    case nativeStakingTitle
    case nativeStakingChevron
    case topUpBanner
    case feeCurrencyNavigationButton
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
    case pendingExpressTransaction

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
        case .feeCurrencyNavigationButton:
            return TokenAccessibilityIdentifiers.feeCurrencyNavigationButton
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
        case .pendingExpressTransaction:
            return TokenAccessibilityIdentifiers.pendingExpressTransaction
        }
    }
}
