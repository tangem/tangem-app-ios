//
//  SomePage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class SomePage: UIElementPage<SomePageUIElement> {
    init(_ app: XCUIApplication) {
        super.init(app: app, rootUIElement: SomePageUIElement.root)
    }
}

enum SomePageUIElement: String, UIElement {
    case root

    var accessibilityIdentifier: String {
        switch self {
        case .root:
            "test"
        }
    }
}
