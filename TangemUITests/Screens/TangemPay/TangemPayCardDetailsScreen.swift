//
//  TangemPayCardDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import UIKit
import TangemAccessibilityIdentifiers

final class TangemPayCardDetailsScreen: ScreenBase<TangemPayCardDetailsScreenElement> {
    private static let replaceCardTitle = "Replace card"
    private static let replacingInProgressText = "Replacing your digital card"

    private lazy var changePinRow = button(.changePinRow)
    private lazy var freezeRowActive = button(.freezeCardRowStateActive)
    private lazy var freezeRowFrozen = button(.freezeCardRowStateFrozen)
    private lazy var moreMenuButton = button(.cardManagementMoreButton)
    private lazy var replaceCardMenuItem = button(Self.replaceCardTitle)
    private lazy var dailyLimitChangeButton = button(.dailyLimitChangeButton)
    private lazy var showDetailsButton = button(.cardDetailsShowButton)
    private lazy var hideDetailsButton = button(.cardDetailsHideButton)
    private lazy var cardNumberValue = staticText(.cardDetailsNumberValue)
    private lazy var cardExpirationValue = staticText(.cardDetailsExpirationValue)
    private lazy var cardCvcValue = staticText(.cardDetailsCvcValue)
    private lazy var copyNumberButton = button(.cardDetailsCopyNumber)
    private lazy var copyExpirationButton = button(.cardDetailsCopyExpiration)
    private lazy var copyCvcButton = button(.cardDetailsCopyCvc)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay card details screen") { _ in
            waitAndAssertTrue(changePinRow, "Change PIN row should be displayed on Tangem Pay card details screen")
            return self
        }
    }

    @discardableResult
    func tapChangePin() -> TangemPayPinScreen {
        XCTContext.runActivity(named: "Tap Change PIN row") { _ in
            changePinRow.waitAndTap()
            return TangemPayPinScreen(app)
        }
    }

    @discardableResult
    func tapFreezeCard() -> TangemPayFreezeConfirmationSheet {
        XCTContext.runActivity(named: "Tap Freeze card row") { _ in
            freezeRowActive.waitAndTap()
            return TangemPayFreezeConfirmationSheet(app)
        }
    }

    @discardableResult
    func tapUnfreezeCard() -> TangemPayUnfreezeConfirmationSheet {
        XCTContext.runActivity(named: "Tap Unfreeze card row") { _ in
            freezeRowFrozen.waitAndTap()
            return TangemPayUnfreezeConfirmationSheet(app)
        }
    }

    @discardableResult
    func verifyCardFrozen() -> Self {
        XCTContext.runActivity(named: "Verify card is frozen (Unfreeze row present)") { _ in
            waitAndAssertTrue(freezeRowFrozen, timeout: .networkRequest, "Unfreeze row should be displayed after freezing")
            return self
        }
    }

    @discardableResult
    func verifyCardActive() -> Self {
        XCTContext.runActivity(named: "Verify card is active (Freeze row present)") { _ in
            waitAndAssertTrue(freezeRowActive, timeout: .networkRequest, "Freeze row should be displayed when card is active")
            return self
        }
    }

    @discardableResult
    func tapBack() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Tap back to return to Tangem Pay payment account") { _ in
            tapBackButton(to: TangemPayMainScreen.self)
        }
    }

    @discardableResult
    func tapChangeDailyLimit() -> TangemPayDailyLimitScreen {
        XCTContext.runActivity(named: "Tap Change on Daily limit row") { _ in
            dailyLimitChangeButton.waitAndTap()
            return TangemPayDailyLimitScreen(app)
        }
    }

    @discardableResult
    func verifyDailyLimitValue(contains expected: String) -> Self {
        XCTContext.runActivity(named: "Verify Daily limit row shows value containing '\(expected)'") { _ in
            let value = app.staticTexts
                .matching(identifier: TangemPayAccessibilityIdentifiers.dailyLimitRowValue)
                .matching(NSPredicate(format: "label CONTAINS %@", expected))
                .firstMatch
            XCTAssertTrue(
                value.waitForExistence(timeout: .networkRequest),
                "Daily limit row should show value containing '\(expected)'"
            )
            return self
        }
    }

    @discardableResult
    func tapReplaceCard() -> TangemPayReissueSheet {
        XCTContext.runActivity(named: "Open Replace card from more menu") { _ in
            openReplaceCardFromMoreMenu()
            return TangemPayReissueSheet(app)
        }
    }

    @discardableResult
    func tapReplaceCardExpectingFeeError() -> Self {
        XCTContext.runActivity(named: "Open Replace card from more menu expecting fee error") { _ in
            openReplaceCardFromMoreMenu()
            return self
        }
    }

    @discardableResult
    func verifyReplacingInProgress() -> Self {
        XCTContext.runActivity(named: "Verify 'Replacing your digital card' state") { _ in
            waitAndAssertTrue(
                app.staticTexts[Self.replacingInProgressText].firstMatch,
                "'Replacing your digital card' should be displayed while reissue is in progress"
            )
            return self
        }
    }

    @discardableResult
    func waitForReissueCompleted() -> Self {
        XCTContext.runActivity(named: "Wait for reissue to complete") { _ in
            waitAndAssertTrue(changePinRow, timeout: .robustUIUpdate, "Card actions should return after reissue completes")
            return self
        }
    }

    @discardableResult
    func verifyFeeUnreachableAlertAndDismiss() -> Self {
        XCTContext.runActivity(named: "Verify reissue fee error alert and dismiss") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Reissue fee error alert should be displayed")

            let title = alert.staticTexts
                .element(matching: NSPredicate(format: "label CONTAINS %@", "Something went wrong"))
                .firstMatch
            XCTAssertTrue(title.exists, "Alert title 'Something went wrong' should be displayed")

            let message = alert.staticTexts
                .element(matching: NSPredicate(format: "label CONTAINS %@", "Replacement fee info unreachable"))
                .firstMatch
            XCTAssertTrue(message.exists, "Alert message 'Replacement fee info unreachable' should be displayed")

            alert.buttons["OK"].waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapShowDetails() -> Self {
        XCTContext.runActivity(named: "Tap Show details on the card") { _ in
            showDetailsButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func waitForRevealedDetails() -> Self {
        XCTContext.runActivity(named: "Wait for card details to be revealed") { _ in
            waitAndAssertTrue(cardNumberValue, timeout: .networkRequest, "Card number value should be displayed after reveal")
            waitAndAssertTrue(cardExpirationValue, "Card expiration value should be displayed after reveal")
            waitAndAssertTrue(cardCvcValue, "Card CVC value should be displayed after reveal")
            return self
        }
    }

    func readCardNumber() -> String {
        XCTContext.runActivity(named: "Read card number") { _ in
            waitAndAssertTrue(cardNumberValue, timeout: .networkRequest, "Card number should be displayed")
            return cardNumberValue.label
        }
    }

    func readCardExpiration() -> String {
        XCTContext.runActivity(named: "Read card expiration") { _ in
            waitAndAssertTrue(cardExpirationValue, "Card expiration should be displayed")
            return cardExpirationValue.label
        }
    }

    func readCardCvc() -> String {
        XCTContext.runActivity(named: "Read card CVC") { _ in
            waitAndAssertTrue(cardCvcValue, "Card CVC should be displayed")
            return cardCvcValue.label
        }
    }

    @discardableResult
    func tapCopyCardNumber() -> Self {
        XCTContext.runActivity(named: "Tap copy card number") { _ in
            copyNumberButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapCopyExpiration() -> Self {
        XCTContext.runActivity(named: "Tap copy expiration date") { _ in
            copyExpirationButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapCopyCvc() -> Self {
        XCTContext.runActivity(named: "Tap copy CVC") { _ in
            copyCvcButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyToastVisible(text: String) -> Self {
        XCTContext.runActivity(named: "Verify toast '\(text)' is visible") { _ in
            let toast = app.staticTexts[text].firstMatch
            waitAndAssertTrue(toast, timeout: .conditional, "Toast with text '\(text)' should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyPasteboard(equals expected: String) -> Self {
        XCTContext.runActivity(named: "Verify pasteboard equals '\(expected)'") { _ in
            let actual = UIPasteboard.general.string ?? ""
            XCTAssertEqual(
                actual,
                expected,
                "Pasteboard should contain '\(expected)' but was '\(actual)'"
            )
            return self
        }
    }

    private func openReplaceCardFromMoreMenu() {
        moreMenuButton.waitAndTap()
        replaceCardMenuItem.waitAndTap()
    }
}

enum TangemPayCardDetailsScreenElement: String, UIElement {
    case changePinRow
    case freezeCardRowStateActive
    case freezeCardRowStateFrozen
    case cardManagementMoreButton
    case reissueCardRow
    case dailyLimitChangeButton
    case cardDetailsShowButton
    case cardDetailsHideButton
    case cardDetailsNumberValue
    case cardDetailsExpirationValue
    case cardDetailsCvcValue
    case cardDetailsCopyNumber
    case cardDetailsCopyExpiration
    case cardDetailsCopyCvc

    var accessibilityIdentifier: String {
        switch self {
        case .changePinRow:
            TangemPayAccessibilityIdentifiers.changePinRow
        case .freezeCardRowStateActive:
            TangemPayAccessibilityIdentifiers.freezeCardRowStateActive
        case .freezeCardRowStateFrozen:
            TangemPayAccessibilityIdentifiers.freezeCardRowStateFrozen
        case .cardManagementMoreButton:
            TangemPayAccessibilityIdentifiers.cardManagementMoreButton
        case .reissueCardRow:
            TangemPayAccessibilityIdentifiers.reissueCardRow
        case .dailyLimitChangeButton:
            TangemPayAccessibilityIdentifiers.dailyLimitChangeButton
        case .cardDetailsShowButton:
            TangemPayAccessibilityIdentifiers.cardDetailsShowButton
        case .cardDetailsHideButton:
            TangemPayAccessibilityIdentifiers.cardDetailsHideButton
        case .cardDetailsNumberValue:
            TangemPayAccessibilityIdentifiers.cardDetailsNumberValue
        case .cardDetailsExpirationValue:
            TangemPayAccessibilityIdentifiers.cardDetailsExpirationValue
        case .cardDetailsCvcValue:
            TangemPayAccessibilityIdentifiers.cardDetailsCvcValue
        case .cardDetailsCopyNumber:
            TangemPayAccessibilityIdentifiers.cardDetailsCopyNumber
        case .cardDetailsCopyExpiration:
            TangemPayAccessibilityIdentifiers.cardDetailsCopyExpiration
        case .cardDetailsCopyCvc:
            TangemPayAccessibilityIdentifiers.cardDetailsCopyCvc
        }
    }
}
