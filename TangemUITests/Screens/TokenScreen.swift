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
    }

    private lazy var moreButton = otherElement(.moreButton)
    private lazy var hideTokenButton = button(.hideTokenButton)
    private lazy var actionButtons = otherElement(.tokenActionButtons)
    private lazy var stakeNotificationButton = button(.stakeNotificationButton)

    // Staking elements
    private lazy var nativeStakingBlock = button(.nativeStakingBlock)
    private lazy var nativeStakingTitle = staticText(.nativeStakingTitle)
    private lazy var nativeStakingChevron = image(.nativeStakingChevron)

    func hideToken(name: String) -> MainScreen {
        moreButton.waitAndTap()
        hideTokenButton.waitAndTap()
        app.alerts["Hide \(name)"].buttons["Hide"].waitAndTap()
        return MainScreen(app)
    }

    @discardableResult
    func validateActionButtonsAvailable() -> Self {
        XCTContext.runActivity(named: "Validate action buttons are available") { _ in
            XCTAssertTrue(actionButtons.waitForExistence(timeout: .robustUIUpdate), "Action buttons container should exist")
            
            // Get all available buttons and their labels for debugging
            let allButtons = actionButtons.buttons.allElementsBoundByIndex
            let buttonLabels = allButtons.map { $0.label }
            
            // Log the container and button information for debugging
            print("Action buttons container exists: \(actionButtons.exists)")
            print("Action buttons container is hittable: \(actionButtons.isHittable)")
            print("Action buttons container identifier: \(actionButtons.identifier)")
            print("Action buttons container label: \(actionButtons.label)")
            print("Action buttons container frame: \(actionButtons.frame)")
            print("Action buttons container elementType: \(actionButtons.elementType)")
            print("Action buttons container value: \(actionButtons.value ?? "nil")")
            print("Action buttons container hasFocus: \(actionButtons.hasFocus)")
            print("Action buttons container isEnabled: \(actionButtons.isEnabled)")
            print("Action buttons container isEnabled: \(actionButtons.isEnabled)")
            print("Action buttons container isEnabled: \(actionButtons.isEnabled)")
            print("Action buttons container isEnabled: \(actionButtons.isEnabled)")
            print("Number of buttons found: \(allButtons.count)")
            print("Button labels: \(buttonLabels)")
            
            // Log details about each button
            for (index, button) in allButtons.enumerated() {
                print("Button \(index): exists=\(button.exists), hittable=\(button.isHittable), enabled=\(button.isEnabled), label='\(button.label)', identifier='\(button.identifier)', frame=\(button.frame), elementType=\(button.elementType), value='\(button.value ?? "nil")', hasFocus=\(button.hasFocus), isEnabled=\(button.isEnabled)")
            }
            
            XCTAssertFalse(buttonLabels.isEmpty, "No action buttons found. Available buttons: \(buttonLabels)")
            
            // Check if Buy button is available
            let buyButton = actionButtons.buttons["Buy"]
            XCTAssertTrue(buyButton.exists, "Buy button should exist. Available buttons: \(buttonLabels)")
            
            return self
        }
    }

    @discardableResult
    func tapActionButton(_ action: TokenAction) -> Self {
        XCTContext.runActivity(named: "Tap token action button: \(action.rawValue)") { _ in
            // First wait for the action buttons container to exist
            XCTAssertTrue(actionButtons.waitForExistence(timeout: .robustUIUpdate), "Action buttons container should exist")
            
            // Get all available buttons for debugging
            let allButtons = actionButtons.buttons.allElementsBoundByIndex
            let buttonLabels = allButtons.map { $0.label }
            
            // Wait for the specific button to appear and be tappable
            let button = actionButtons.buttons[action.rawValue]
            XCTAssertTrue(button.waitForExistence(timeout: .robustUIUpdate), "Button '\(action.rawValue)' should exist. Available buttons: \(buttonLabels)")
            
            // Log button information for debugging
            print("Button '\(action.rawValue)' exists: \(button.exists)")
            print("Button '\(action.rawValue)' is hittable: \(button.isHittable)")
            print("Button '\(action.rawValue)' is enabled: \(button.isEnabled)")
            print("Button '\(action.rawValue)' label: '\(button.label)'")
            print("Button '\(action.rawValue)' identifier: '\(button.identifier)'")
            print("Button '\(action.rawValue)' frame: \(button.frame)")
            print("Button '\(action.rawValue)' elementType: \(button.elementType)")
            print("Button '\(action.rawValue)' value: '\(button.value ?? "nil")'")
            print("Button '\(action.rawValue)' hasFocus: \(button.hasFocus)")
            print("Button '\(action.rawValue)' isEnabled: \(button.isEnabled)")
            print("Button '\(action.rawValue)' isEnabled: \(button.isEnabled)")
            print("Button '\(action.rawValue)' isEnabled: \(button.isEnabled)")
            print("Button '\(action.rawValue)' isEnabled: \(button.isEnabled)")
            
            XCTAssertTrue(button.waitForState(state: .hittable, for: .robustUIUpdate), "Button '\(action.rawValue)' should be hittable")
            
            button.waitAndTap()
            return self
        }
    }

    func tapBuyButton() -> OnrampScreen {
        tapActionButton(.buy)
        return OnrampScreen(app)
    }

    func tapSwapButton() -> SwapScreen {
        tapActionButton(.swap)
        return SwapScreen(app)
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
}

enum TokenScreenElement: String, UIElement {
    case moreButton
    case hideTokenButton
    case tokenActionButtons
    case stakeNotificationButton
    case nativeStakingBlock
    case nativeStakingTitle
    case nativeStakingChevron

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
        }
    }
}
