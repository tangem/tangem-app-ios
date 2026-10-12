//
//  TangemPayOfferInfoRow.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

enum TangemPayOfferInfoRow: String {
    case issueFee
    case issueTime
    case deliverTo
    case deliveryFee
    case deliveryTime

    var accessibilityIdentifier: String {
        TangemPayAccessibilityIdentifiers.orderCardInfoRow(rawValue)
    }
}

extension Screen {
    func offerInfoRow(_ row: TangemPayOfferInfoRow) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: row.accessibilityIdentifier)
            .firstMatch
    }

    func offerInfoRow(_ row: TangemPayOfferInfoRow, containing text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: row.accessibilityIdentifier)
            .matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, text))
            .firstMatch
    }

    func verifyOfferInfoRow(_ row: TangemPayOfferInfoRow, contains texts: [String]) {
        XCTContext.runActivity(named: "Verify '\(row.rawValue)' row contains \(texts)") { _ in
            for text in texts {
                waitAndAssertTrue(
                    offerInfoRow(row, containing: text),
                    timeout: .networkRequest,
                    "'\(row.rawValue)' row should contain '\(text)'"
                )
            }
        }
    }

    func verifyOfferInfoRow(_ row: TangemPayOfferInfoRow, doesNotContain text: String) {
        XCTContext.runActivity(named: "Verify '\(row.rawValue)' row does not contain '\(text)'") { _ in
            waitAndAssertTrue(offerInfoRow(row), timeout: .networkRequest, "'\(row.rawValue)' row should be displayed")
            XCTAssertFalse(
                offerInfoRow(row, containing: text).exists,
                "'\(row.rawValue)' row should not contain '\(text)'"
            )
        }
    }
}
