//
//  TangemPayUnavailableRegionScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayUnavailableRegionScreen: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts[Localization.tangempayRegionUnavailableTitle].firstMatch
    private lazy var joinWaitlistButton = app.buttons[Localization.tangempayRegionUnavailablePrimaryButton].firstMatch
    private lazy var selectAnotherRegionButton = app.buttons[Localization.tangempayRegionUnavailableSecondaryButton].firstMatch
    private lazy var closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for region unavailable screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Region unavailable title should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyContent() -> Self {
        XCTContext.runActivity(named: "Verify region unavailable screen content") { _ in
            waitAndAssertTrue(title, "Region unavailable title should be displayed")
            let expectedDescription = Localization.tangempayRegionUnavailableDescription.singleLine
            let description = app.staticTexts
                .matching(NSPredicate(format: "label BEGINSWITH %@", String(expectedDescription.prefix(Constants.descriptionPrefixLength))))
                .firstMatch
            waitAndAssertTrue(description, "Region unavailable description should be displayed")
            XCTAssertEqual(description.label.singleLine, expectedDescription, "Region unavailable description should match")
            waitAndAssertTrue(joinWaitlistButton, "Join the waitlist button should be displayed")
            waitAndAssertTrue(selectAnotherRegionButton, "Select another region button should be displayed")
            waitAndAssertTrue(closeButton, "Close button should be displayed")
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
    func tapJoinWaitlist() -> TangemPayWaitlistSheet {
        XCTContext.runActivity(named: "Tap Join the waitlist") { _ in
            joinWaitlistButton.waitAndTap()
            return TangemPayWaitlistSheet(app)
        }
    }

    @discardableResult
    func close<Destination: Screen>(to destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Close region unavailable screen") { _ in
            closeButton.waitAndTap()
            XCTAssertTrue(title.waitForNonExistence(timeout: .robustUIUpdate), "Region unavailable screen should be closed")
            return Destination(app)
        }
    }
}

private extension String {
    var singleLine: String {
        replacingOccurrences(of: "\n", with: " ")
    }
}

private extension TangemPayUnavailableRegionScreen {
    enum Constants {
        static let descriptionPrefixLength = 20
    }
}
