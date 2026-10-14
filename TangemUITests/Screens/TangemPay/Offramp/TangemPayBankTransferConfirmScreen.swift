//
//  TangemPayBankTransferConfirmScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayBankTransferConfirmScreen: ScreenBase<TangemPayBankTransferConfirmScreenElement> {
    private lazy var sendButton = button(.sendButton)
    private lazy var title = app.staticTexts[Localization.tangempayWithdrawBankConfirmTitle].firstMatch
    private lazy var amountCard = button(.amountCard)
    private lazy var railRowElements = app.descendants(matching: .any).matching(identifier: TangemPayBankTransferConfirmScreenElement.railRow.accessibilityIdentifier)
    private lazy var railRowButton = button(.railRow)
    private lazy var sectionButtons = app.buttons.matching(identifier: TangemPayBankTransferConfirmScreenElement.section.accessibilityIdentifier)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Confirm transfer") { _ in
            waitAndAssertTrue(sendButton, timeout: .networkRequest, "Send button should be displayed")
            waitAndAssertTrue(title, "Screen should be titled '\(Localization.tangempayWithdrawBankConfirmTitle)'")
            return self
        }
    }

    @discardableResult
    func verifyRecipientDetails(_ values: [String]) -> Self {
        XCTContext.runActivity(named: "Verify the recipient details \(values)") { _ in
            for value in values {
                let predicate = NSPredicate(
                    format: "identifier == %@ AND label CONTAINS %@",
                    TangemPayBankTransferConfirmScreenElement.section.accessibilityIdentifier,
                    value
                )
                waitAndAssertTrue(
                    app.descendants(matching: .any).matching(predicate).firstMatch,
                    "Confirm transfer should show '\(value)'"
                )
            }
            return self
        }
    }

    @discardableResult
    func verifyAmountCard(amount: String, balance: String) -> Self {
        XCTContext.runActivity(named: "Verify the amount card shows \(amount) out of \(balance)") { _ in
            waitAndAssertTrue(amountCard, "Amount card should be displayed as a tappable card")
            for text in [amount, balance] {
                XCTAssertTrue(amountCard.label.contains(text), "Amount card should show '\(text)'. Actual: '\(amountCard.label)'")
            }
            return self
        }
    }

    @discardableResult
    func tapAmountCard() -> TangemPayBankTransferAmountScreen {
        XCTContext.runActivity(named: "Tap the amount card") { _ in
            amountCard.waitAndTap()
            return TangemPayBankTransferAmountScreen(app).waitForScreen()
        }
    }

    @discardableResult
    func verifyRail(_ rail: TangemPayBankTransferRail) -> Self {
        XCTContext.runActivity(named: "Verify the \(rail.title) route") { _ in
            let displayed = NSPredicate { [railRowElements] _, _ in rail.isDisplayed(by: railRowElements) }
            XCTAssertEqual(
                XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: displayed, object: nil)], timeout: .conditional),
                .completed,
                "Route row should show \(rail.texts)"
            )
            return self
        }
    }

    @discardableResult
    func verifyRailEditable(_ isEditable: Bool) -> Self {
        XCTContext.runActivity(named: "Verify the route is\(isEditable ? "" : " not") editable") { _ in
            waitAndAssertTrue(railRowElements.firstMatch, "Route row should be displayed")
            XCTAssertEqual(railRowButton.exists, isEditable, "Route row should\(isEditable ? "" : " not") be tappable")
            return self
        }
    }

    @discardableResult
    func tapSection(containing value: String) -> TangemPayBankTransferWizardScreen {
        XCTContext.runActivity(named: "Tap the details card with '\(value)'") { _ in
            let section = sectionButtons.matching(NSPredicate(format: "label CONTAINS %@", value)).firstMatch
            waitAndAssertTrue(section, "Details card with '\(value)' should be displayed")
            scrollToElement(section)
            section.waitAndTap()
            return TangemPayBankTransferWizardScreen(app)
        }
    }

    @discardableResult
    func verifySectionsNotEditable() -> Self {
        XCTContext.runActivity(named: "Verify the recipient and bank details are read-only") { _ in
            let section = app.descendants(matching: .any).matching(identifier: TangemPayBankTransferConfirmScreenElement.section.accessibilityIdentifier)
            waitAndAssertTrue(section.firstMatch, "Recipient details should be displayed")
            XCTAssertEqual(sectionButtons.count, 0, "Recipient and bank details should not be tappable")
            return self
        }
    }

    @discardableResult
    func tapSendExpectingError() -> TangemPayBankTransferErrorScreen {
        tapSend()
        return TangemPayBankTransferErrorScreen(app).waitForScreen()
    }

    @discardableResult
    func tapSend() -> TangemPayBankTransferSuccessScreen {
        XCTContext.runActivity(named: "Tap Send") { _ in
            XCTAssertTrue(sendButton.waitForState(state: .enabled, for: .conditional), "Send should be enabled")
            sendButton.waitAndTap()
            return TangemPayBankTransferSuccessScreen(app)
        }
    }
}

enum TangemPayBankTransferConfirmScreenElement: String, UIElement {
    case section
    case sendButton
    case amountCard
    case railRow

    var accessibilityIdentifier: String {
        switch self {
        case .section:
            TangemPayOfframpAccessibilityIdentifiers.confirmSection
        case .sendButton:
            TangemPayOfframpAccessibilityIdentifiers.confirmSendButton
        case .amountCard:
            TangemPayOfframpAccessibilityIdentifiers.confirmAmountCard
        case .railRow:
            TangemPayOfframpAccessibilityIdentifiers.confirmRailRow
        }
    }
}
