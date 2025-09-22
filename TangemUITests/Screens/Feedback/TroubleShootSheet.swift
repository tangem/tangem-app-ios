//
//  TroubleShootSheet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers
import Foundation

final class TroubleShootSheet: ScreenBase<TroubleShootSheetElement> {
    private lazy var tryAgainButton = button(.tryAgainButton)
    private lazy var readMoreButton = button(.readMoreButton)
    private lazy var requestSupportButton = button(.requestSupportButton)
    private lazy var cancelButton = button(.cancelButton)

    func validateTroubleShootSheet() {
        XCTContext.runActivity(named: "Validate TroubleShoot Sheet") { _ in
            XCTAssertTrue(tryAgainButton.waitForExistence(timeout: .robustUIUpdate), "Try Again button should exist")
            XCTAssertTrue(readMoreButton.waitForExistence(timeout: .robustUIUpdate), "Read More button should exist")
            XCTAssertTrue(requestSupportButton.waitForExistence(timeout: .robustUIUpdate), "Request Support button should exist")
            XCTAssertTrue(cancelButton.waitForExistence(timeout: .robustUIUpdate), "Cancel button should exist")
        }
    }

    func requestSupport() -> MailScreen {
        XCTContext.runActivity(named: "Tap Request Support button") { _ in
            XCTAssertTrue(requestSupportButton.waitForExistence(timeout: .robustUIUpdate), "Request Support button should exist")
            requestSupportButton.waitAndTap()
            return MailScreen(app)
        }
    }
}

enum TroubleShootSheetElement: String, UIElement {
    case tryAgainButton
    case readMoreButton
    case requestSupportButton
    case cancelButton

    var accessibilityIdentifier: String {
        switch self {
        case .tryAgainButton:
            "Try again"
        case .readMoreButton:
            "Read more"
        case .requestSupportButton:
            "Request support"
        case .cancelButton:
            "Cancel"
        }
    }
}
