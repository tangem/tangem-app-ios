//
//  AddFundsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class AddFundsScreen: ScreenBase<AddFundsScreenElement> {
    private lazy var buyRow = button(.buyRow)
    private lazy var swapRow = button(.swapRow)
    private lazy var receiveRow = button(.receiveRow)

    @discardableResult
    func tapBuy() -> OnrampScreen {
        XCTContext.runActivity(named: "Tap Buy row on Add funds screen") { _ in
            buyRow.waitAndTap()
            return OnrampScreen(app)
        }
    }

    @discardableResult
    func tapSwap() -> SwapStoriesScreen {
        XCTContext.runActivity(named: "Tap Swap row on Add funds screen") { _ in
            swapRow.waitAndTap()
            return SwapStoriesScreen(app)
        }
    }

    @discardableResult
    func tapCloseButton() -> MainScreen {
        XCTContext.runActivity(named: "Tap Close button") { _ in
            // Multiple close buttons may exist in the sheet stack; tap the topmost hittable one
            let closeButtons = app.buttons.matching(identifier: CommonUIAccessibilityIdentifiers.closeButton)
            for i in 0 ..< closeButtons.count {
                let button = closeButtons.element(boundBy: i)
                if button.isHittable {
                    button.tap()
                    return
                }
            }
            XCTFail("No hittable Close button found on Add Funds screen")
        }
        return MainScreen(app)
    }
}

enum AddFundsScreenElement: String, UIElement {
    case buyRow
    case swapRow
    case receiveRow

    var accessibilityIdentifier: String {
        switch self {
        case .buyRow:
            return ActionButtonsAccessibilityIdentifiers.addFundsBuyRow
        case .swapRow:
            return ActionButtonsAccessibilityIdentifiers.addFundsSwapRow
        case .receiveRow:
            return ActionButtonsAccessibilityIdentifiers.addFundsReceiveRow
        }
    }
}
