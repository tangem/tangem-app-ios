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
            tapTopmostHittableCloseButton(context: "Add Funds screen")
        }
        return MainScreen(app)
    }

    @discardableResult
    func closeToMarketsTokenDetails() -> MarketsTokenDetailsScreen {
        XCTContext.runActivity(named: "Close 'Get token' screen") { _ in
            tapTopmostHittableCloseButton(context: "'Get token' screen")
        }
        return MarketsTokenDetailsScreen(app)
    }

    /// Several `CommonUIAccessibilityIdentifiers.closeButton` elements can coexist in the sheet stack; tap the topmost hittable one.
    private func tapTopmostHittableCloseButton(context: String) {
        let closeButtons = app.buttons.matching(identifier: CommonUIAccessibilityIdentifiers.closeButton)
        let anyHittable = NSPredicate { _, _ in
            (0 ..< closeButtons.count).contains { closeButtons.element(boundBy: $0).isHittable }
        }
        let expectation = XCTNSPredicateExpectation(predicate: anyHittable, object: nil)
        guard XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate) == .completed else {
            XCTFail("No hittable Close button found on \(context)")
            return
        }

        for i in 0 ..< closeButtons.count where closeButtons.element(boundBy: i).isHittable {
            closeButtons.element(boundBy: i).tap()
            return
        }

        XCTFail("Close button on \(context) became non-hittable before it could be tapped")
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
