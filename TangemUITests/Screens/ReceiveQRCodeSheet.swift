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

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait receive QR code sheet is complete") { _ in
            waitAndAssertTrue(qrCodeImage, "QR code image should be displayed")
            waitAndAssertTrue(addressHeader, "Address header should be displayed")
            waitAndAssertTrue(addressText, "Address text should be displayed")
        }
        return self
    }
}

enum ReceiveQRCodeSheetElement: String, UIElement {
    case qrCodeImage
    case addressHeader
    case addressText

    var accessibilityIdentifier: String {
        switch self {
        case .qrCodeImage:
            return QRCodeAccessibilityIdentifiers.qrCodeImage
        case .addressHeader:
            return QRCodeAccessibilityIdentifiers.addressHeader
        case .addressText:
            return QRCodeAccessibilityIdentifiers.addressText
        }
    }
}
