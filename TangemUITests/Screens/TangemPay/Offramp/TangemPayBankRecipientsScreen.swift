//
//  TangemPayBankRecipientsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayBankRecipientsScreen: ScreenBase<TangemPayBankRecipientsScreenElement> {
    private lazy var rows = app.buttons.matching(identifier: TangemPayOfframpAccessibilityIdentifiers.recipientsRow)
    private lazy var searchEmptyText = staticText(.searchEmptyText)
    private lazy var searchField = app.descendants(matching: .any)
        .matching(
            NSPredicate(
                format: "identifier == %@ OR elementType == %d",
                TangemPayOfframpAccessibilityIdentifiers.recipientsSearchField,
                XCUIElement.ElementType.searchField.rawValue
            )
        )
        .firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the Bank transfers list") { _ in
            waitAndAssertTrue(rows.firstMatch, timeout: .networkRequest, "Bank transfers list should show recipients")
            return self
        }
    }

    @discardableResult
    func verifyRecipients(_ recipients: [TangemPayBankRecipient]) -> Self {
        XCTContext.runActivity(named: "Verify the list shows \(recipients.map(\.fullName))") { _ in
            for recipient in recipients {
                let row = self.row(recipient)
                waitAndAssertTrue(row, "'\(recipient.fullName)' should be listed")
                XCTAssertTrue(
                    row.label.contains(recipient.accountNumber),
                    "'\(recipient.fullName)' row should show '\(recipient.accountNumber)'. Actual: '\(row.label)'"
                )
                XCTAssertTrue(
                    recipient.isMonogramLeading(in: row.label),
                    "'\(recipient.fullName)' row should start with the monogram '\(recipient.monogram)'. Actual: '\(row.label)'"
                )
                XCTAssertEqual(
                    row.label.contains(Localization.tangempayWithdrawBankRecipientBusiness),
                    recipient.isBusiness,
                    "'\(recipient.fullName)' row should\(recipient.isBusiness ? "" : " not") be marked '\(Localization.tangempayWithdrawBankRecipientBusiness)'. Actual: '\(row.label)'"
                )
            }
            return self
        }
    }

    @discardableResult
    func verifyOnlyRecipients(_ recipients: [TangemPayBankRecipient]) -> Self {
        XCTContext.runActivity(named: "Verify only \(recipients.map(\.fullName)) are listed") { _ in
            let countMatches = NSPredicate(format: "count == %d", recipients.count)
            let expectation = XCTNSPredicateExpectation(predicate: countMatches, object: rows)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .conditional),
                .completed,
                "The list should show \(recipients.count) recipients, but shows \(rows.count)"
            )
            verifyRecipients(recipients)
            return self
        }
    }

    @discardableResult
    func search(_ query: String) -> Self {
        XCTContext.runActivity(named: "Search for '\(query)'") { _ in
            waitAndAssertTrue(searchField, "Search field should be displayed")
            clearText(element: searchField)
            typeWithFocus(into: searchField, text: query)
            return self
        }
    }

    @discardableResult
    func verifyNothingFound() -> Self {
        XCTContext.runActivity(named: "Verify the empty search state") { _ in
            waitAndAssertTrue(searchEmptyText, timeout: .conditional, "Empty search state should be displayed")
            XCTAssertEqual(searchEmptyText.label, Localization.tangempayWithdrawBankRecipientsSearchEmpty, "Empty search state should read '\(Localization.tangempayWithdrawBankRecipientsSearchEmpty)'")
            XCTAssertEqual(rows.count, 0, "No recipients should be listed")
            return self
        }
    }

    @discardableResult
    func tapRecipient(_ recipient: TangemPayBankRecipient) -> TangemPayBankTransferAmountScreen {
        XCTContext.runActivity(named: "Tap recipient '\(recipient.fullName)'") { _ in
            row(recipient).waitAndTap()
            return TangemPayBankTransferAmountScreen(app).waitForScreen()
        }
    }

    private func row(_ recipient: TangemPayBankRecipient) -> XCUIElement {
        rows.matching(NSPredicate(format: "label CONTAINS %@", recipient.fullName)).firstMatch
    }
}

enum TangemPayBankRecipientsScreenElement: String, UIElement {
    case searchEmptyText

    var accessibilityIdentifier: String {
        switch self {
        case .searchEmptyText:
            TangemPayOfframpAccessibilityIdentifiers.recipientsSearchEmpty
        }
    }
}
