//
//  AddressesInfoScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import UIKit
import TangemAccessibilityIdentifiers

final class AddressesInfoScreen: ScreenBase<AddressesInfoScreenElement> {
    private lazy var addressesInfoText = staticText(.addressesInfoText)

    @discardableResult
    func copyJSON() -> String {
        XCTContext.runActivity(named: "Copy JSON to clipboard") { _ in
            waitAndAssertTrue(addressesInfoText, "Addresses text info field should exist")
            return addressesInfoText.label
        }
    }
}

enum AddressesInfoScreenElement: String, UIElement {
    case addressesInfoText

    var accessibilityIdentifier: String {
        switch self {
        case .addressesInfoText:
            return CommonUIAccessibilityIdentifiers.addressesInfoText
        }
    }
}
