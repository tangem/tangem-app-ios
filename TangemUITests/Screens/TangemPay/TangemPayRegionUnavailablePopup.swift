//
//  TangemPayRegionUnavailablePopup.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayRegionUnavailablePopup: Screen {
    let app: XCUIApplication

    private lazy var icon = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.popupIcon].firstMatch
    private lazy var title = app.staticTexts[Localization.moneyAccountMainStatusDialogCountryNotSupportedTitle].firstMatch
    private lazy var contactSupportLink = app.links[Localization.commonContactSupport].firstMatch
    private lazy var selectAnotherRegionButton = app.buttons[TangemPayAccessibilityIdentifiers.popupSecondaryButton].firstMatch
    private lazy var hideAccountButton = app.buttons[Localization.moneyAccountMainStatusDialogHideAccount].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for Not available in your region yet sheet") { _ in
            waitAndAssertTrue(title, timeout: .conditional, "Region unavailable sheet title should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyContent() -> Self {
        XCTContext.runActivity(named: "Verify Not available in your region yet sheet content") { _ in
            waitAndAssertTrue(icon, "Region unavailable sheet icon should be displayed")
            waitAndAssertTrue(title, "Region unavailable sheet title should be displayed")
            let description = app.staticTexts
                .matching(NSPredicate(format: "label BEGINSWITH %@", Localization.moneyAccountMainStatusDialogCountryNotSupportedDescription))
                .firstMatch
            waitAndAssertTrue(description, "Region unavailable sheet description should be displayed")
            waitAndAssertTrue(contactSupportLink, "Contact support link should be displayed")
            waitAndAssertTrue(selectAnotherRegionButton, "Select another region button should be displayed")
            XCTAssertEqual(
                selectAnotherRegionButton.label,
                Localization.tangempayRegionUnavailableSecondaryButton,
                "Secondary button should offer selecting another region"
            )
            waitAndAssertTrue(hideAccountButton, "Hide account from home button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapSelectAnotherRegion() -> TangemPayGeoSelectionScreen {
        XCTContext.runActivity(named: "Tap Select another region") { _ in
            selectAnotherRegionButton.waitAndTap()
            return TangemPayGeoSelectionScreen(app)
        }
    }

    @discardableResult
    func tapHideAccount() -> MainScreen {
        XCTContext.runActivity(named: "Tap Hide account from home") { _ in
            hideAccountButton.waitAndTap()
            XCTAssertTrue(title.waitForNonExistence(timeout: .robustUIUpdate), "Region unavailable sheet should be closed")
            return MainScreen(app)
        }
    }
}
