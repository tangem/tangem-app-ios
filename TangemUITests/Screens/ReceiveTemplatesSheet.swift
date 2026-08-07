//
//  ReceiveTemplatesSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers
import Foundation

final class ReceiveTemplatesSheet: ScreenBase<ReceiveTemplatesSheetElement> {
    enum AddressType {
        case segwit
        case legacy
    }

    private lazy var showQRCodeButton = button(.showQRCodeButton)
    private lazy var segwitAddress = staticText(.segwitAddress)
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func validateShowQRCodeButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Show QR code button is displayed") { _ in
            waitAndAssertTrue(showQRCodeButton, "Show QR code button should be displayed")
        }
        return self
    }

    func tapShowQRCode() -> ReceiveQRCodeSheet {
        XCTContext.runActivity(named: "Tap Show QR code button") { _ in
            showQRCodeButton.waitAndTap()
            return ReceiveQRCodeSheet(app)
        }
    }

    func tapShowQRCode(_ type: AddressType) -> ReceiveQRCodeSheet {
        XCTContext.runActivity(named: "Tap Show QR code button for \(type) address") { _ in
            showQRCodeButton(for: type).waitAndTap()
            return ReceiveQRCodeSheet(app)
        }
    }

    func readSegwitAddress() -> String {
        XCTContext.runActivity(named: "Read segwit Bitcoin address") { _ in
            waitAndAssertTrue(segwitAddress, "Segwit address should be displayed")
            return QRCodeDecoder.normalizeAddress(segwitAddress.label)
        }
    }

    @discardableResult
    func swipeToNextAddress() -> Self {
        XCTContext.runActivity(named: "Swipe to next address type") { _ in
            waitAndAssertTrue(segwitAddress, "Address page should be displayed")
            segwitAddress.swipeLeft()
        }
        return self
    }

    /// Asserts each address type's QR encodes its displayed address, and that the two address types differ.
    @discardableResult
    func assertBothAddressTypesEncodeDisplayedAddressAndDiffer() -> Self {
        XCTContext.runActivity(named: "Assert each address type's QR encodes its address and the two differ") { _ in
            let firstQRCode = tapShowQRCode(.segwit)
            let firstAddress = firstQRCode.assertQRCodeEncodesDisplayedAddress()

            let secondQRCode = firstQRCode
                .tapBack()
                .swipeToNextAddress()
                .tapShowQRCode(.legacy)
            let secondAddress = secondQRCode.assertQRCodeEncodesDisplayedAddress()

            XCTAssertNotEqual(firstAddress, secondAddress, "Both address types should differ")
        }
        return self
    }

    func close() -> TokenScreen {
        XCTContext.runActivity(named: "Close Receive sheet") { _ in
            closeButton.waitAndTap()
            return TokenScreen(app)
        }
    }

    private func showQRCodeButton(for type: AddressType) -> XCUIElement {
        switch type {
        case .segwit:
            return button(.segwitShowQRCodeButton)
        case .legacy:
            return button(.legacyShowQRCodeButton)
        }
    }
}

enum ReceiveTemplatesSheetElement: String, UIElement {
    case showQRCodeButton
    case segwitShowQRCodeButton
    case legacyShowQRCodeButton
    case segwitAddress
    case legacyAddress
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .showQRCodeButton:
            return "Show QR code"
        case .segwitShowQRCodeButton:
            return ReceiveAccessibilityIdentifiers.segwitShowQRCodeButton
        case .legacyShowQRCodeButton:
            return ReceiveAccessibilityIdentifiers.legacyShowQRCodeButton
        case .segwitAddress:
            return ReceiveAccessibilityIdentifiers.segwitAddress
        case .legacyAddress:
            return ReceiveAccessibilityIdentifiers.legacyAddress
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        }
    }
}
