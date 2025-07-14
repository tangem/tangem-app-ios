//
//  OnrampScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampScreen: ScreenBase<OnrampScreenElement> {
    private lazy var decimalNumberTextField = textField(.decimalNumberTextField)

    func validateTextFieldValue(_ expectedValue: String) {
        XCTContext.runActivity(named: "Validate TextField value is '\(expectedValue)'") { _ in
            let actualValue = decimalNumberTextField.getValue()
            XCTAssertEqual(actualValue, expectedValue, "TextField value should be '\(expectedValue)' but was '\(actualValue)'")
        }
    }
}

enum OnrampScreenElement: String, UIElement {
    case decimalNumberTextField

    var accessibilityIdentifier: String {
        switch self {
        case .decimalNumberTextField:
            return CommonUIAccessibilityIdentifiers.decimalNumberTextField
        }
    }
}
