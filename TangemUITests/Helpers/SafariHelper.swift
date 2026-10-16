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

    func waitForPageURL(containing expected: String) {
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: .robustUIUpdate), "Safari should be opened")
        let addressBar = safari.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@ OR identifier == %@", "Address", "TabBarItemTitle"))
            .firstMatch
        XCTAssertTrue(addressBar.waitForExistence(timeout: .robustUIUpdate), "Safari address bar should exist")
        let urlField = safari.textFields["Address"].firstMatch
        for _ in 0 ..< Constants.addressBarTapAttempts {
            if addressBar.exists {
                addressBar.tapEvenIfNotHittable()
            }
            if urlField.waitForExistence(timeout: .quick), urlField.waitForValue(timeout: Constants.urlWaitPerAttempt, where: { $0.contains(expected) }) {
                return
            }
        }
        let lastValue = urlField.exists ? urlField.getValue() : ""
        XCTFail("Safari URL should contain '\(expected)' but was '\(lastValue)'")
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

private extension SafariHelper {
    enum Constants {
        static let addressBarTapAttempts = 3
        static let urlWaitPerAttempt: TimeInterval = .robustUIUpdate / 3
    }
}
