//
//  SendQRScannerScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendQRScannerScreen: ScreenBase<SendQRScannerScreenElement> {
    private lazy var infoTextLabel = staticText(.infoText)
    private lazy var closeButton = button(.closeButton)
    private lazy var galleryButton = button(.galleryButton)
    private lazy var flashToggleButton = button(.flashToggleButton)

    @discardableResult
    func waitForDisplay(networkName: String) -> Self {
        XCTContext.runActivity(named: "Validate Send QR scanner screen is displayed") { _ in
            waitAndAssertTrue(infoTextLabel, "Instruction text should be visible")
            let expectedText = "Please align your QR code with the square to scan it. Ensure you scan \(networkName) network address."
            XCTAssertEqual(
                infoTextLabel.label,
                expectedText,
                "Instruction text should match the expected template"
            )
            waitAndAssertTrue(closeButton, "Close button should exist")
            waitAndAssertTrue(galleryButton, "Gallery button should exist")
            waitAndAssertTrue(flashToggleButton, "Flash toggle button should exist")
        }
        return self
    }

    @discardableResult
    func tapCloseButton() -> SendScreen {
        XCTContext.runActivity(named: "Close Send QR scanner screen") { _ in
            closeButton.waitAndTap()
        }
        return SendScreen(app)
    }
}

enum SendQRScannerScreenElement: UIElement {
    case infoText
    case closeButton
    case galleryButton
    case flashToggleButton

    var accessibilityIdentifier: String {
        switch self {
        case .infoText:
            return SendQRScannerAccessibilityIdentifiers.infoText
        case .closeButton:
            return SendQRScannerAccessibilityIdentifiers.closeButton
        case .galleryButton:
            return SendQRScannerAccessibilityIdentifiers.galleryButton
        case .flashToggleButton:
            return SendQRScannerAccessibilityIdentifiers.flashToggleButton
        }
    }
}
