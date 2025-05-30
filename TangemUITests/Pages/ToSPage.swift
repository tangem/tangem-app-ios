//
//  ToSPage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class ToSPage: UIElementPage<ToSPageUIElement> {
    private(set) lazy var acceptButton = button(.acceptButton)
    private(set) lazy var laterButton = button(.laterButton)

    init(_ app: XCUIApplication) {
        super.init(app: app, rootUIElement: ToSPageUIElement.root)
    }
}

enum ToSPageUIElement: String, UIElement {
    case root
    case acceptButton
    case laterButton

    var accessibilityIdentifier: String {
        switch self {
        case .root:
            "TosPage"
        case .acceptButton:
            "AcceptButton"
        case .laterButton:
            "LaterButton"
        }
    }
}
