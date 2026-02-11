//
//  EnvironmentSetupScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class EnvironmentSetupScreen: ScreenBase<EnvironmentSetupScreenElement> {
    private lazy var addressesInfoButton = button(.addressesInfoButton)

    @discardableResult
    func openAddressesInfo() -> AddressesInfoScreen {
        XCTContext.runActivity(named: "Open Addresses Info") { _ in
            waitAndAssertTrue(addressesInfoButton, "Addresses Info button should exist")
            addressesInfoButton.waitAndTapWithScroll()
            return AddressesInfoScreen(app)
        }
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Environment Setup screen") { _ in
            waitAndAssertTrue(addressesInfoButton, "Addresses Info button should be displayed")
            return self
        }
    }
}

enum EnvironmentSetupScreenElement: String, UIElement {
    case addressesInfoButton

    var accessibilityIdentifier: String {
        switch self {
        case .addressesInfoButton:
            return CommonUIAccessibilityIdentifiers.addressesInfoButton
        }
    }
}
