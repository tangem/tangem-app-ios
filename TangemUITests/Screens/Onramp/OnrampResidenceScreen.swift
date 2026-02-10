//
//  OnrampResidenceScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampResidenceScreen: ScreenBase<OnrampResidenceScreenElement> {
    private lazy var grabber = otherElement(.grabber)
    private lazy var searchField = textField(.searchField)

    @discardableResult
    func validateResidenceScreenOpened() -> Self {
        XCTContext.runActivity(named: "Validate Residence screen is opened") { _ in
            XCTAssertTrue(searchField.waitForExistence(timeout: .robustUIUpdate), "Residence screen search field should exist")
        }
        return self
    }

    @discardableResult
    func searchForCountry(_ countryName: String) -> Self {
        XCTContext.runActivity(named: "Search for country '\(countryName)'") { _ in
            XCTAssertTrue(searchField.waitForExistence(timeout: .robustUIUpdate), "Search field should exist")
            searchField.tap()
            searchField.typeText(countryName)
        }
        return self
    }

    func selectCountry(_ countryName: String) -> OnrampSettingsScreen {
        XCTContext.runActivity(named: "Select country '\(countryName)'") { _ in
            let countryButton = app.buttons[OnrampAccessibilityIdentifiers.countryItem(code: countryName)]
            countryButton.waitAndTap()

            return OnrampSettingsScreen(app)
        }
    }

    func dismissResidenceSelector() -> OnrampSettingsScreen {
        XCTContext.runActivity(named: "Dismiss residence screen by swiping down on grabber") { _ in
            _ = grabber.waitForExistence(timeout: .robustUIUpdate)
            fastSwipeDownOnGrabber()

            return OnrampSettingsScreen(app)
        }
    }

    private func fastSwipeDownOnGrabber() {
        let startCoordinate = grabber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.0))
        startCoordinate.press(
            forDuration: 0.02,
            thenDragTo: endCoordinate,
            withVelocity: .fast,
            thenHoldForDuration: .zero
        )
    }
}

enum OnrampResidenceScreenElement: String, UIElement {
    case grabber
    case searchField

    var accessibilityIdentifier: String {
        switch self {
        case .grabber:
            return CommonUIAccessibilityIdentifiers.grabber
        case .searchField:
            return OnrampAccessibilityIdentifiers.residenceSearchField
        }
    }
}
