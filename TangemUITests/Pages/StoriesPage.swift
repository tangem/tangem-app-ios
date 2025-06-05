//
//  StoriesPage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StoriesPage: UIElementPage<StoriesPageUIElement> {
    private(set) lazy var scanButton = button(.scanButton)
    private(set) lazy var cardMockWalletTwo = button(.cardMockWalletTwo)

    init(_ app: XCUIApplication) {
        super.init(app: app, rootUIElement: StoriesPageUIElement.root)
    }
}

enum StoriesPageUIElement: String, UIElement {
    case root
    case scanButton
    case cardMockWalletTwo

    var accessibilityIdentifier: String {
        switch self {
        case .root:
            AccessibilityIdentifiers.Stories.root
        case .scanButton:
            AccessibilityIdentifiers.Stories.scanButton
        case .cardMockWalletTwo:
            AccessibilityIdentifiers.Stories.cardMockWalletTwo
        }
    }
}
