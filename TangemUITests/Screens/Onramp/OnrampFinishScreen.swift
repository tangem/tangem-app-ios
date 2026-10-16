//
//  OnrampFinishScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampFinishScreen: ScreenBase<OnrampFinishScreenElement> {
    private lazy var header = staticText(.header)
    private lazy var transactionTime = staticText(.transactionTime)
    private lazy var fiatIcon = image(.fiatIcon)
    private lazy var fiatAmount = textField(.fiatAmount)
    private lazy var cryptoAmount = staticText(.cryptoAmount)
    private lazy var providerIcon = image(.providerIcon)
    private lazy var providerName = staticText(.providerName)

    @discardableResult
    func waitForInProgressTitle() -> Self {
        XCTContext.runActivity(named: "Validate In progress title") { _ in
            waitAndAssertTrue(header, "In progress title should exist")
            XCTAssertEqual(header.label, Localization.commonInProgress, "Title should be 'In progress'")
        }
        return self
    }

    @discardableResult
    func verifyTransactionDate(between start: Date, and end: Date) -> Self {
        XCTContext.runActivity(named: "Validate transaction date and time") { _ in
            waitAndAssertTrue(transactionTime, "Transaction date and time should exist")
            let formatter = DateFormatter()
            formatter.locale = UITestLocale.locale
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            let acceptedDates = Set([start, end].map { formatter.string(from: $0) })
            XCTAssertTrue(
                acceptedDates.contains { transactionTime.label.contains($0) },
                "Transaction time '\(transactionTime.label)' should contain one of \(acceptedDates)"
            )
        }
        return self
    }

    @discardableResult
    func verifyPurchaseDetails(fiatAmount expectedFiat: String, cryptoAmount expectedCrypto: String, provider: String) -> Self {
        XCTContext.runActivity(named: "Validate purchase details") { _ in
            waitAndAssertTrue(fiatIcon, "Fiat currency icon should exist")
            waitAndAssertTrue(fiatAmount, "Fiat amount should exist")
            XCTAssertTrue(
                fiatAmount.getValue().contains(expectedFiat),
                "Fiat amount '\(fiatAmount.getValue())' should contain '\(expectedFiat)'"
            )
            waitAndAssertTrue(cryptoAmount, "Crypto amount should exist")
            XCTAssertTrue(
                cryptoAmount.label.contains(expectedCrypto),
                "Crypto amount '\(cryptoAmount.label)' should contain '\(expectedCrypto)'"
            )
            waitAndAssertTrue(providerIcon, "Provider icon should exist")
            waitAndAssertTrue(providerName, "Provider name should exist")
            XCTAssertEqual(providerName.label, provider, "Provider name mismatch")
        }
        return self
    }

    @discardableResult
    func verifyTransactionStatus(_ expectedStatus: String) -> Self {
        XCTContext.runActivity(named: "Validate transaction status '\(expectedStatus)' and footer") { _ in
            waitAndAssertTrue(app.staticTexts[expectedStatus].firstMatch, "Transaction status '\(expectedStatus)' should exist")
            waitAndAssertTrue(
                app.staticTexts[Localization.onrampTransactionStatusFooterText].firstMatch,
                "Transaction status footer should exist"
            )
        }
        return self
    }

    @discardableResult
    func waitForCloseButton() -> Self {
        XCTContext.runActivity(named: "Validate Close button") { _ in
            waitAndAssertTrue(closeButton, "Close button should exist")
        }
        return self
    }

    func tapClose<Destination: Screen>(to destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Tap Close on In progress screen") { _ in
            closeButton.waitAndTap()
            XCTAssertTrue(header.waitForState(state: .doesntExist, for: .robustUIUpdate), "In progress screen should be dismissed")
            return Destination(app)
        }
    }

    private var closeButton: XCUIElement {
        app.buttons[SendAccessibilityIdentifiers.sendViewNextButton].firstMatch
    }
}

enum OnrampFinishScreenElement: String, UIElement {
    case header
    case transactionTime
    case fiatIcon
    case fiatAmount
    case cryptoAmount
    case providerIcon
    case providerName

    var accessibilityIdentifier: String {
        switch self {
        case .header:
            return SendAccessibilityIdentifiers.finishHeader
        case .transactionTime:
            return SendAccessibilityIdentifiers.finishTransactionTime
        case .fiatIcon:
            return OnrampAccessibilityIdentifiers.finishFiatIcon
        case .fiatAmount:
            return OnrampAccessibilityIdentifiers.finishFiatAmount
        case .cryptoAmount:
            return OnrampAccessibilityIdentifiers.finishCryptoAmount
        case .providerIcon:
            return OnrampAccessibilityIdentifiers.finishProviderIcon
        case .providerName:
            return OnrampAccessibilityIdentifiers.finishProviderName
        }
    }
}
