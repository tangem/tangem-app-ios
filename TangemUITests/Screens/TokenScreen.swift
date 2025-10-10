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

    private lazy var moreButton = otherElement(.moreButton)
    private lazy var hideTokenButton = button(.hideTokenButton)
    private lazy var actionButtons = otherElement(.tokenActionButtons)
    private lazy var stakeNotificationButton = button(.stakeNotificationButton)
    private lazy var topUpBanner = staticText(.topUpBanner)

    // Staking elements
    private lazy var nativeStakingBlock = button(.nativeStakingBlock)
    private lazy var nativeStakingTitle = staticText(.nativeStakingTitle)
    private lazy var nativeStakingChevron = image(.nativeStakingChevron)

    private lazy var availableSegment = button(.availableSegment)

    // Balance elements
    private lazy var totalBalance = staticText(.totalBalance)
    private lazy var availableBalance = staticText(.availableBalance)
    private lazy var stakingBalance = staticText(.stakingBalance)

    func hideToken(name: String) -> MainScreen {
        moreButton.waitAndTap()
        hideTokenButton.waitAndTap()
        app.alerts["Hide \(name)"].buttons["Hide"].waitAndTap()
        return MainScreen(app)
    }

    @discardableResult
    func tapHideFromContextMenu() -> MainScreen {
        XCTContext.runActivity(named: "Tap Hide from context menu") { _ in
            app.buttons["Hide token"].waitAndTap()
            app.alerts.firstMatch.buttons["Hide"].waitAndTap()
            return MainScreen(app)
        }
    }

    @discardableResult
    func tapActionButton(_ action: TokenAction) -> Self {
        XCTContext.runActivity(named: "Tap token action button: \(action.rawValue)") { _ in
            XCTAssertTrue(actionButtons.waitForExistence(timeout: .robustUIUpdate), "Action buttons container should exist")

            let button = actionButtons.buttons[action.rawValue]

            button.waitAndTap()
            return self
        }
    }

    func tapBuyButton() -> OnrampScreen {
        tapActionButton(.buy)
        return OnrampScreen(app)
    }

    func tapSwapButton() -> SwapStoriesScreen {
        tapActionButton(.swap)
        return SwapStoriesScreen(app)
    }

    func tapSendButton() -> SendScreen {
        tapActionButton(.send)
        return SendScreen(app)
    }

    func openStakeDetails() -> StakingDetailsScreen {
        XCTContext.runActivity(named: "Tap stake button in notification") { _ in
            stakeNotificationButton.waitAndTap()
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
    func validateStakingInfo() -> Self {
        XCTContext.runActivity(named: "Validate staking information on token screen") { _ in
            XCTAssertTrue(nativeStakingBlock.waitForExistence(timeout: .robustUIUpdate), "Native staking block should be displayed")
            XCTAssertTrue(nativeStakingTitle.waitForExistence(timeout: .robustUIUpdate), "Native staking title should be displayed")
            XCTAssertTrue(nativeStakingChevron.waitForExistence(timeout: .robustUIUpdate), "Navigation chevron should be displayed")

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
    func validateTopUpWalletBannerNotExists() -> Self {
        XCTContext.runActivity(named: "Validate 'Top up your wallet' banner not exists") { _ in
            topUpBanner.waitForState(state: .doesntExist)
            XCTAssertFalse(topUpBanner.exists, "Top up wallet banner should not be displayed")
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
        XCTContext.runActivity(named: "Tap Available segment") { _ in
            availableSegment.waitAndTap()
            return self
        }
    }

    // MARK: - Balance Methods

    func getTotalBalance() -> String {
        XCTContext.runActivity(named: "Get total balance") { _ in
            XCTAssertTrue(totalBalance.waitForExistence(timeout: .robustUIUpdate), "Total balance element should exist")
            return totalBalance.label
        }
    }

    func getAvailableBalance() -> String {
        XCTContext.runActivity(named: "Get available balance") { _ in
            XCTAssertTrue(availableBalance.waitForExistence(timeout: .robustUIUpdate), "Available balance element should exist")
            return availableBalance.label
        }
    }

    func getStakingBalance() -> String {
        XCTContext.runActivity(named: "Get staking balance") { _ in
            XCTAssertTrue(stakingBalance.waitForExistence(timeout: .robustUIUpdate), "Staking balance element should exist")
            return stakingBalance.label
        }
    }
}

enum TokenScreenElement: String, UIElement {
    case moreButton
    case hideTokenButton
    case tokenActionButtons
    case stakeNotificationButton
    case nativeStakingBlock
    case nativeStakingTitle
    case nativeStakingChevron
    case topUpBanner
    case availableSegment
    case totalBalance
    case availableBalance
    case stakingBalance

    var accessibilityIdentifier: String {
        switch self {
        case .moreButton:
            return TokenAccessibilityIdentifiers.moreButton
        case .hideTokenButton:
            return TokenAccessibilityIdentifiers.hideTokenButton
        case .tokenActionButtons:
            return TokenAccessibilityIdentifiers.actionButtonsList
        case .stakeNotificationButton:
            return CommonUIAccessibilityIdentifiers.notificationButton
        case .nativeStakingBlock:
            return TokenAccessibilityIdentifiers.nativeStakingBlock
        case .nativeStakingTitle:
            return TokenAccessibilityIdentifiers.nativeStakingTitle
        case .nativeStakingChevron:
            return TokenAccessibilityIdentifiers.nativeStakingChevron
        case .topUpBanner:
            return TokenAccessibilityIdentifiers.topUpWalletBanner
        case .availableSegment:
            return "Available"
        case .totalBalance:
            return TokenAccessibilityIdentifiers.totalBalance
        case .availableBalance:
            return TokenAccessibilityIdentifiers.availableBalance
        case .stakingBalance:
            return TokenAccessibilityIdentifiers.stakingBalance
        }
    }
}
