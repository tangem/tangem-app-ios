//
//  SafariHelper.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

struct SafariHelper {
    let safari: XCUIApplication

    init(safari: XCUIApplication = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")) {
        self.safari = safari
    }

    func openDeeplink(_ deeplink: String) {
        let urlField = safari.textFields["Address"]
        XCTAssertTrue(urlField.waitForExistence(timeout: 5), "Address bar not found")
        urlField.tap()

        let clearButton = safari.buttons["ClearTextButton"]
        if clearButton.isHittable {
            clearButton.tap()
        }

        UIPasteboard.general.string = deeplink
        urlField.doubleTap()
        safari.menuItems["Paste and Go"].tap()

        dismissToolTipIfNeeded()
    }

    func dismissToolTipIfNeeded() {
        let closeButton = safari.buttons["Close"]
        if closeButton.waitForExistence(timeout: 3), closeButton.isHittable {
            closeButton.tap()
        }
    }

    func tapOpenButton() {
        let openButton = safari.buttons["Open"]
        if openButton.waitForExistence(timeout: 5) {
            openButton.tap()
        }
    }

    func tapOpenTangemApp() {
        safari.buttons["Open Tangem App"].waitAndTap()
        safari.buttons["Open"].waitAndTap()
    }
}
