//
//  PushPermissionRequestPage.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class PushPermissionRequestScreen: ScreenBase<PushPermissionRequestElement> {
    private lazy var title = staticText(.title)
    private lazy var acceptButton = button(.acceptButton)
    private lazy var laterButton = button(.laterButton)

    func postponePermissionRequest() {
        XCTContext.runActivity(named: "Postpone permission request") { _ in
            laterButton.waitAndTap()
            return MainScreen(app)
        }
    }

    func isShown() -> Bool {
        return title.waitForExistence(timeout: .robustUIUpdate)
    }

    func handlePermissionRequest() {
        if isShown() {
            postponePermissionRequest()
        }
    }
}

enum PushPermissionRequestElement: String, UIElement {
    case title
    case acceptButton
    case laterButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            PushPermissionAccessibilityIdentifiers.title
        case .acceptButton:
            PushPermissionAccessibilityIdentifiers.allowButton
        case .laterButton:
            PushPermissionAccessibilityIdentifiers.laterButton
        }
    }
}
