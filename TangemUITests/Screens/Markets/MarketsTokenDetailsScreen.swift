//
//  MarketsTokenDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

final class MarketsTokenDetailsScreen: ScreenBase<MarketsTokenDetailsScreenElement> {
    private lazy var listedOnExchangesButton = button(.listedOnExchangesButton)

    @discardableResult
    func verifyListedOnExchangesBlock() -> Self {
        XCTContext.runActivity(named: "Verify 'Listed on exchanges' block is displayed") { _ in
            XCTAssertTrue(
                listedOnExchangesButton.waitForExistence(timeout: .robustUIUpdate),
                "Listed on exchanges button should exist and be visible"
            )
            return self
        }
    }

    @discardableResult
    func openExchanges() -> MarketsExchangeScreen {
        XCTContext.runActivity(named: "Open exchanges list") { _ in
            if !listedOnExchangesButton.isHittable {
                app.swipeUp()
            }

            listedOnExchangesButton.waitAndTap()
            return MarketsExchangeScreen(app)
        }
    }

    @discardableResult
    func verifyListedOnExchangesBlockEmpty() -> Self {
        XCTContext.runActivity(named: "Verify 'Listed on exchanges' block is empty and disabled") {
            _ in
            let listedOnLabel = app.staticTexts[
                MarketsAccessibilityIdentifiers.listedOnExchangesTitle
            ]

            if !listedOnLabel.waitForExistence(timeout: .robustUIUpdate) {
                app.swipeUp()
            }

            XCTAssertTrue(listedOnLabel.exists, "'Listed on' label should exist")

            let noExchangesLabel = app.staticTexts[
                MarketsAccessibilityIdentifiers.listedOnExchangesEmptyText
            ]

            XCTAssertTrue(noExchangesLabel.exists, "'No exchanges found' label should exist")

            return self
        }
    }
}

enum MarketsTokenDetailsScreenElement: String, UIElement {
    case listedOnExchangesButton

    var accessibilityIdentifier: String {
        switch self {
        case .listedOnExchangesButton:
            MarketsAccessibilityIdentifiers.listedOnExchanges
        }
    }
}
