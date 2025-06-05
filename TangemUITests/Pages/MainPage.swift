//
//  MainPage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class MainPage: UIElementPage<MainPageUIElement> {
    private(set) lazy var buyTitle = staticText(.buyTitle)
    private(set) lazy var exchangeTitle = staticText(.exchangeTitle)
    private(set) lazy var sellTitle = staticText(.sellTitle)

    init(_ app: XCUIApplication) {
        super.init(app: app, rootUIElement: MainPageUIElement.root)
    }
}

enum MainPageUIElement: String, UIElement {
    case root
    case buyTitle
    case exchangeTitle
    case sellTitle

    var accessibilityIdentifier: String {
        switch self {
        case .root:
            AccessibilityIdentifiers.Main.root
        case .buyTitle:
            AccessibilityIdentifiers.Main.buyTitle
        case .exchangeTitle:
            AccessibilityIdentifiers.Main.exchangeTitle
        case .sellTitle:
            AccessibilityIdentifiers.Main.sellTitle
        }
    }
}
