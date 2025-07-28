//
//  OnrampSettingsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampSettingsScreen: ScreenBase<OnrampSettingsScreenElement> {
    private lazy var residenceButton = button(.residenceButton)

    func tapResidenceButton() -> OnrampResidenceScreen {
        XCTContext.runActivity(named: "Tap Residence button") { _ in
            residenceButton.waitAndTap()
            return OnrampResidenceScreen(app)
        }
    }

    @discardableResult
    func validateSelectedCountry(_ expectedCountry: String) -> Self {
        XCTContext.runActivity(named: "Validate selected country is '\(expectedCountry)' on settings screen") { _ in
            XCTAssertTrue(residenceButton.waitForExistence(timeout: .robustUIUpdate), "Residence button should exist")

            let buttonText = residenceButton.label
            XCTAssertTrue(buttonText.contains(expectedCountry), "Residence button should contain '\(expectedCountry)' but was '\(buttonText)'")
        }
        return self
    }

    func dismissOnrampSettings() -> OnrampScreen {
        XCTContext.runActivity(named: "Dismiss settings screen by back navigation") { _ in
            _ = residenceButton.waitForExistence(timeout: .robustUIUpdate)

            app.navigationBars["Settings"].buttons["Back"].waitAndTap()

            return OnrampScreen(app)
        }
    }
}

enum OnrampSettingsScreenElement: String, UIElement {
    case residenceButton

    var accessibilityIdentifier: String {
        switch self {
        case .residenceButton:
            return OnrampAccessibilityIdentifiers.residenceButton
        }
    }
}
