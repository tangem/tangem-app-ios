//
//  OnrampProviderWebPage.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class OnrampProviderWebPage: Screen {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func tapOffer(fiatAmount: Int) -> Self {
        XCTContext.runActivity(named: "Tap provider offer for $\(fiatAmount)") { _ in
            let predicate = NSPredicate(format: NSPredicateFormat.labelContains.rawValue, "for $\(fiatAmount)")
            let offer = app.webViews.buttons.matching(predicate).firstMatch
            offer.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyTotalPaidAmountMatches(_ fiatAmount: Int) -> Self {
        XCTContext.runActivity(named: "Verify 'Total paid' amount matches entered $\(fiatAmount)") { _ in
            let expectedAmount = "$\(fiatAmount).00"
            let predicate = NSPredicate(format: NSPredicateFormat.labelContains.rawValue, expectedAmount)
            let amountText = app.webViews.staticTexts.matching(predicate).firstMatch
            waitAndAssertTrue(amountText, "Total paid amount '\(expectedAmount)' should be displayed on the provider page")
            return self
        }
    }

    @discardableResult
    func verifyReceivingWalletMatches(_ fullAddress: String) -> Self {
        XCTContext.runActivity(named: "Verify provider receiving wallet matches the wallet address") { _ in
            let predicate = NSPredicate(format: NSPredicateFormat.labelContains.rawValue, "Receiving wallet")
            let walletButton = app.webViews.buttons.matching(predicate).firstMatch
            waitAndAssertTrue(walletButton, "Receiving wallet element should be displayed on the provider page")

            guard let masked = walletButton.label
                .components(separatedBy: .whitespacesAndNewlines)
                .first(where: { $0.contains("\u{2026}") })
            else {
                XCTFail("Masked address not found in '\(walletButton.label)'")
                return self
            }

            let parts = masked.components(separatedBy: "\u{2026}")
            guard parts.count == 2 else {
                XCTFail("Masked address '\(masked)' has an unexpected format")
                return self
            }

            XCTAssertTrue(
                fullAddress.hasPrefix(parts[0]) && fullAddress.hasSuffix(parts[1]),
                "Provider receiving wallet '\(masked)' should match wallet address '\(fullAddress)'"
            )
            return self
        }
    }
}
