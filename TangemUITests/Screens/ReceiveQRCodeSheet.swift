//
//  ReceiveQRCodeSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers
import Foundation

final class ReceiveQRCodeSheet: ScreenBase<ReceiveQRCodeSheetElement> {
    private lazy var qrCodeImage = image(.qrCodeImage)
    private lazy var addressHeader = staticText(.addressHeader)
    private lazy var addressText = button(.addressText)
    private lazy var copyButton = button(.copyButton)
    private lazy var shareButton = button(.shareButton)

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait receive QR code sheet is complete") { _ in
            waitAndAssertTrue(qrCodeImage, "QR code image should be displayed")
            waitAndAssertTrue(addressHeader, "Address header should be displayed")
            waitAndAssertTrue(addressText, "Address text should be displayed")
        }
        return self
    }

    func readDisplayedAddress() -> String {
        XCTContext.runActivity(named: "Read displayed address") { _ in
            waitAndAssertTrue(addressText, "Address text should be displayed")
            return QRCodeDecoder.normalizeAddress(addressText.label)
        }
    }

    /// Decodes the QR image and asserts it encodes the displayed address; returns that address.
    @discardableResult
    func assertQRCodeEncodesDisplayedAddress() -> String {
        XCTContext.runActivity(named: "Assert QR code encodes the displayed address") { _ in
            waitForDisplay()
            let displayedAddress = readDisplayedAddress()

            guard let decoded = QRCodeDecoder.decode(from: qrCodeImage) else {
                XCTFail("QR code should be decodable")
                return displayedAddress
            }

            XCTAssertEqual(
                QRCodeDecoder.normalizeAddress(decoded),
                displayedAddress,
                "QR code should encode the displayed address"
            )
            return displayedAddress
        }
    }

    @discardableResult
    func verifyDisplayedAddress(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Verify the QR sheet shows address '\(expected)'") { _ in
            XCTAssertEqual(readDisplayedAddress(), expected, "QR sheet should show the expected address")
            return self
        }
    }

    @discardableResult
    func verifyCopyAndShareButtonsDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Copy and Share buttons are displayed") { _ in
            waitAndAssertTrue(copyButton, "Copy button should be displayed")
            waitAndAssertTrue(shareButton, "Share button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapCopy() -> Self {
        XCTContext.runActivity(named: "Tap Copy button on QR code sheet") { _ in
            copyButton.waitAndTap()
            return self
        }
    }

    func tapShare() -> ShareSheet {
        XCTContext.runActivity(named: "Tap Share button on QR code sheet") { _ in
            shareButton.waitAndTap()
            return ShareSheet(app)
        }
    }

    func tapBack() -> ReceiveTemplatesSheet {
        tapBackButton(to: ReceiveTemplatesSheet.self)
    }
}

enum ReceiveQRCodeSheetElement: String, UIElement {
    case qrCodeImage
    case addressHeader
    case addressText
    case copyButton
    case shareButton

    var accessibilityIdentifier: String {
        switch self {
        case .qrCodeImage:
            return QRCodeAccessibilityIdentifiers.qrCodeImage
        case .addressHeader:
            return QRCodeAccessibilityIdentifiers.addressHeader
        case .addressText:
            return QRCodeAccessibilityIdentifiers.addressText
        case .copyButton:
            return QRCodeAccessibilityIdentifiers.copyButton
        case .shareButton:
            return QRCodeAccessibilityIdentifiers.shareButton
        }
    }
}
