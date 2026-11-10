//
//  SystemURLOpener.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

struct SystemURLOpener {
    private let springboard = XCUIApplication(bundleIdentifier: Constants.springboardBundleId)

    func open(_ link: String) {
        guard let url = URL(string: link) else {
            XCTFail("Invalid link: \(link)")
            return
        }

        XCUIDevice.shared.system.open(url)

        let openButton = springboard.buttons[Constants.openButtonTitle]
        if openButton.waitForExistence(timeout: .quick) {
            openButton.tap()
        }
    }
}

private extension SystemURLOpener {
    enum Constants {
        static let springboardBundleId = "com.apple.springboard"
        static let openButtonTitle = "Open"
    }
}
