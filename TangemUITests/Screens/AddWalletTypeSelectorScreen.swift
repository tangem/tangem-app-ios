//
//  AddWalletTypeSelectorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class AddWalletTypeSelectorScreen: ScreenBase<AddWalletTypeSelectorScreenElement> {
    private var hardwareWalletRows: XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", Localization.introductionCreateWalletHardwareTitle)
        )
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Add Wallet type selector") { _ in
            waitAndAssertTrue(hardwareWalletRows.firstMatch, "Hardware wallet row should be displayed")
            return self
        }
    }

    @discardableResult
    func tapHardwareWallet() -> DetailsScreen {
        XCTContext.runActivity(named: "Tap Hardware wallet") { _ in
            waitAndAssertTrue(hardwareWalletRows.firstMatch, "Hardware wallet row should be displayed")

            guard let row = hardwareWalletRows.firstHittableElement() else {
                XCTFail("Hardware wallet row should be hittable")
                return DetailsScreen(app)
            }

            row.tap()
            return DetailsScreen(app)
        }
    }
}

enum AddWalletTypeSelectorScreenElement: String, UIElement {
    case hardwareWalletRow

    var accessibilityIdentifier: String {
        rawValue
    }
}
