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

    func validate() {
        XCTContext.runActivity(named: "Validate MainPage") { _ in
            XCTAssertTrue(buyTitle.exists)
            XCTAssertTrue(exchangeTitle.exists)
            XCTAssertTrue(sellTitle.exists)
        }
    }
}

enum MainScreenElement: String, UIElement {
    case buyTitle
    case exchangeTitle
    case sellTitle

    var accessibilityIdentifier: String {
        switch self {
        case .buyTitle:
            MainAccessibilityIdentifiers.buyTitle
        case .exchangeTitle:
            MainAccessibilityIdentifiers.exchangeTitle
        case .sellTitle:
            MainAccessibilityIdentifiers.sellTitle
        }
    }
}
