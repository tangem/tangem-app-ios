//
//  MainScreen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class MainScreen: ScreenBase<MainScreenElement> {
    private lazy var buyTitle = staticText(.buyTitle)
    private lazy var exchangeTitle = staticText(.exchangeTitle)
    private lazy var sellTitle = staticText(.sellTitle)
    private lazy var tokensList = otherElement(.tokensList)

    func validate() {
        XCTContext.runActivity(named: "Validate MainPage") { _ in
            XCTAssertTrue(buyTitle.waitForExistence(timeout: .quickUIUpdate))
            XCTAssertTrue(exchangeTitle.exists)
            XCTAssertTrue(sellTitle.exists)
        }
    }

    func tapToken(_ label: String) -> TokenScreen {
        XCTContext.runActivity(named: "Tap token with label: \(label)") { _ in
            tokensList.staticTextByLabel(label: label).waitAndTap()
            return TokenScreen(app)
        }
    }

    func validateTokenNotExists(_ label: String) {
        _ = tokensList.waitForExistence(timeout: .quickUIUpdate)
        XCTContext.runActivity(named: "Validate token with label '\(label)' does not exist") { _ in
            let tokenElement = tokensList.staticTextByLabel(label: label)
            XCTAssertFalse(tokenElement.exists, "Token with label '\(label)' should not exist in the list")
        }
    }
}

enum MainScreenElement: String, UIElement {
    case buyTitle
    case exchangeTitle
    case sellTitle
    case tokensList

    var accessibilityIdentifier: String {
        switch self {
        case .buyTitle:
            MainAccessibilityIdentifiers.buyTitle
        case .exchangeTitle:
            MainAccessibilityIdentifiers.exchangeTitle
        case .sellTitle:
            MainAccessibilityIdentifiers.sellTitle
        case .tokensList:
            MainAccessibilityIdentifiers.tokensList
        }
    }
}
