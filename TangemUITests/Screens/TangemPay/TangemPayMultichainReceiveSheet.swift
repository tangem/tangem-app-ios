//
//  TangemPayMultichainReceiveSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayMultichainReceiveSheet: ScreenBase<TangemPayMultichainReceiveSheetElement> {
    private lazy var heading = staticText(.heading)
    private lazy var copyButton = button(.copyButton)
    private lazy var showQRButton = button(.showQRButton)
    private lazy var shareButton = button(.shareButton)

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the multichain receive sheet") { _ in
            waitAndAssertTrue(heading, timeout: .networkRequest, "Receive sheet heading should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyWarning(title expectedTitle: String, description expectedDescription: String) -> Self {
        XCTContext.runActivity(named: "Verify the receive sheet warning") { _ in
            waitAndAssertTrue(
                element(withLabelContaining: expectedTitle),
                timeout: .conditional,
                "Warning title '\(expectedTitle)' should be displayed"
            )
            waitAndAssertTrue(
                element(withLabelContaining: expectedDescription),
                "Warning description '\(expectedDescription)' should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyHeading(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Verify the receive sheet heading is '\(expected)'") { _ in
            waitAndAssertTrue(heading, timeout: .conditional, "Heading should be displayed")
            XCTAssertEqual(heading.label, expected, "Heading should be '\(expected)'")
            return self
        }
    }

    @discardableResult
    func verifyTokenIcons(_ symbols: [String]) -> Self {
        XCTContext.runActivity(named: "Verify the receive sheet shows icons for \(symbols)") { _ in
            for symbol in symbols {
                let icon = app.descendants(matching: .any)
                    .matching(identifier: TangemPayAccessibilityIdentifiers.multichainReceiveSheetTokenIcon(symbol: symbol))
                    .firstMatch
                waitAndAssertTrue(icon, timeout: .conditional, "Token icon for '\(symbol)' should be displayed")
            }
            return self
        }
    }

    @discardableResult
    func verifyAddress(_ expected: String) -> Self {
        XCTContext.runActivity(named: "Verify the receive sheet shows address '\(expected)'") { _ in
            XCTAssertEqual(readAddress(), expected, "Receive sheet should show the network deposit address")
            return self
        }
    }

    func readAddress() -> String {
        XCTContext.runActivity(named: "Read the displayed deposit address") { _ in
            waitAndAssertTrue(addressLabel, timeout: .conditional, "Deposit address should be displayed")
            return addressLabel.label
        }
    }

    @discardableResult
    func verifyActionButtonsDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Copy, Show QR and Share buttons") { _ in
            waitAndAssertTrue(copyButton, timeout: .conditional, "Copy button should be displayed")
            waitAndAssertTrue(showQRButton, "Show QR button should be displayed")
            waitAndAssertTrue(shareButton, "Share button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapCopy() -> Self {
        XCTContext.runActivity(named: "Tap Copy on the receive sheet") { _ in
            copyButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapShowQRCode() -> ReceiveQRCodeSheet {
        XCTContext.runActivity(named: "Tap Show QR on the receive sheet") { _ in
            showQRButton.waitAndTap()
            return ReceiveQRCodeSheet(app)
        }
    }

    @discardableResult
    func tapShare() -> ShareSheet {
        XCTContext.runActivity(named: "Tap Share on the receive sheet") { _ in
            shareButton.waitAndTap()
            return ShareSheet(app)
        }
    }

    private func element(withLabelContaining text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, text))
            .firstMatch
    }

    private var addressLabel: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: TangemPayAccessibilityIdentifiers.multichainReceiveSheetAddress)
            .firstMatch
    }
}

enum TangemPayMultichainReceiveSheetElement: String, UIElement {
    case heading
    case copyButton
    case showQRButton
    case shareButton

    var accessibilityIdentifier: String {
        switch self {
        case .heading:
            TangemPayAccessibilityIdentifiers.multichainReceiveSheetHeading
        case .copyButton:
            TangemPayAccessibilityIdentifiers.multichainReceiveSheetCopyButton
        case .showQRButton:
            TangemPayAccessibilityIdentifiers.multichainReceiveSheetShowQRButton
        case .shareButton:
            TangemPayAccessibilityIdentifiers.multichainReceiveSheetShareButton
        }
    }
}
