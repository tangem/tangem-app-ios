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
    private lazy var cardNameEditButton = button(.cardNameEditButton)
    private lazy var changePinRow = button(.changePinRow)
    private lazy var freezeRowActive = button(.freezeCardRowStateActive)
    private lazy var freezeRowFrozen = button(.freezeCardRowStateFrozen)
    private lazy var moreMenuButton = button(.cardManagementMoreButton)
    private lazy var replaceCardMenuItem = button(Localization.tangempayCardDetailsReissueCard)
    private lazy var closeCardMenuItem = app.buttons
        .matching(NSPredicate(
            format: "identifier IN %@",
            [TangemPayAccessibilityIdentifiers.closeCardRow, TangemPayAccessibilityIdentifiers.closeCardRowLastCard]
        ))
        .firstMatch
    private lazy var closeCardMenuItemLastCard = app.buttons[TangemPayAccessibilityIdentifiers.closeCardRowLastCard].firstMatch
    private lazy var dailyLimitChangeButton = button(.dailyLimitChangeButton)
    private lazy var showDetailsButton = button(.cardDetailsShowButton)
    private lazy var hideDetailsButton = button(.cardDetailsHideButton)
    private lazy var cardNumberValue = staticText(.cardDetailsNumberValue)
    private lazy var cardExpirationValue = staticText(.cardDetailsExpirationValue)
    private lazy var cardCvcValue = staticText(.cardDetailsCvcValue)
    private lazy var copyNumberButton = button(.cardDetailsCopyNumber)
    private lazy var copyExpirationButton = button(.cardDetailsCopyExpiration)
    private lazy var copyCvcButton = button(.cardDetailsCopyCvc)
    private lazy var applePayGuideBanner = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.addToApplePayGuideBanner].firstMatch
    private lazy var applePayGuideBannerCloseButton = app.buttons[TangemPayAccessibilityIdentifiers.addToApplePayGuideBannerCloseButton].firstMatch
    private lazy var plasticContactSupportButton = button(.plasticContactSupportButton)
    private lazy var plasticActivateButton = button(.plasticActivateCardButton)
    /// Type-agnostic: the issuing message is a plain container, not guaranteed to surface as a specific element type.
    private lazy var cardIssuingMessage = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.cardIssuingMessage].firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay card details screen") { _ in
            waitAndAssertTrue(changePinRow, "Change PIN row should be displayed on Tangem Pay card details screen")
            return self
        }
    }

    @discardableResult
    func tapCardName() -> TangemPayCardRenameScreen {
        XCTContext.runActivity(named: "Tap card name to start renaming") { _ in
            cardNameEditButton.waitAndTap()
            return TangemPayCardRenameScreen(app)
        }
    }

    @discardableResult
    func verifyCardName(contains expected: String) -> Self {
        XCTContext.runActivity(named: "Verify card name contains '\(expected)'") { _ in
            let nameButton = app.buttons
                .matching(identifier: TangemPayAccessibilityIdentifiers.cardNameEditButton)
                .matching(NSPredicate(format: "label CONTAINS %@", expected))
                .firstMatch
            waitAndAssertTrue(nameButton, timeout: .networkRequest, "Card name should contain '\(expected)'")
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

    /// The same row leads to the current PIN sheet instead of PIN entry once a PIN is set on the card.
    @discardableResult
    func tapPinCode() -> TangemPayPinCheckSheet {
        XCTContext.runActivity(named: "Tap PIN code row") { _ in
            changePinRow.waitAndTap()
            return TangemPayPinCheckSheet(app)
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
    func verifyCardActionsLockedWhileFrozen() -> Self {
        XCTContext.runActivity(named: "Verify Details and PIN are disabled and the daily limit cannot be edited") { _ in
            waitAndAssertTrue(showDetailsButton, "Details button should be displayed on a frozen card")
            showDetailsButton.waitForState(state: .disabled)
            waitAndAssertTrue(changePinRow, "PIN button should be displayed on a frozen card")
            changePinRow.waitForState(state: .disabled)
            verifyDailyLimitValue(contains: Constants.currencySymbol)
            XCTAssertTrue(
                dailyLimitChangeButton.waitForNonExistence(timeout: .conditional),
                "Daily limit Edit button should be hidden while the card is frozen"
            )
            return self
        }
    }

    @discardableResult
    func verifyCardActionsAvailable() -> Self {
        XCTContext.runActivity(named: "Verify Details, PIN and daily limit Edit are enabled") { _ in
            waitAndAssertTrue(showDetailsButton, "Details button should be displayed on an active card")
            showDetailsButton.waitForState(state: .enabled)
            waitAndAssertTrue(changePinRow, "PIN button should be displayed on an active card")
            changePinRow.waitForState(state: .enabled)
            waitAndAssertTrue(dailyLimitChangeButton, "Daily limit Edit button should be displayed on an active card")
            dailyLimitChangeButton.waitForState(state: .enabled)
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
    func tapCloseCard() -> TangemPayCloseCardSheet {
        XCTContext.runActivity(named: "Open Close card from more menu") { _ in
            moreMenuButton.waitAndTap()
            closeCardMenuItem.waitAndTap()
            return TangemPayCloseCardSheet(app)
        }
    }

    @discardableResult
    func verifyCloseCardDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Close card is displayed but disabled") { _ in
            moreMenuButton.waitAndTap()
            waitAndAssertTrue(closeCardMenuItem, "Close card menu item should be displayed")
            closeCardMenuItem.waitForState(state: .disabled)
            return self
        }
    }

    @discardableResult
    func verifyCloseCardShowsLastCardHint() -> Self {
        XCTContext.runActivity(named: "Verify Close card carries the last-card hint") { _ in
            waitAndAssertTrue(
                closeCardMenuItemLastCard,
                timeout: .conditional,
                "Close card should carry the last-card hint for the only card"
            )
            return self
        }
    }

    @discardableResult
    func verifyCardClosingInProgress() -> Self {
        XCTContext.runActivity(named: "Verify 'Closing your card' state") { _ in
            waitAndAssertTrue(
                app.staticTexts[Localization.tangempayCardPageClosingBannerTitle].firstMatch,
                timeout: .networkRequest,
                "'Closing your card' should be displayed while the card is being closed"
            )
            return self
        }
    }

    @discardableResult
    func waitForCardClosingCompleted() -> Self {
        XCTContext.runActivity(named: "Wait for the card closing to complete") { _ in
            XCTAssertTrue(
                app.staticTexts[Localization.tangempayCardPageClosingBannerTitle].firstMatch.waitForNonExistence(timeout: .networkRequest),
                "'Closing your card' should disappear once the close order completes"
            )
            waitAndAssertTrue(changePinRow, timeout: .networkRequest, "Card actions should return after the card is closed")
            return self
        }
    }

    @discardableResult
    func verifyCardNameNotDisplayed(_ name: String) -> Self {
        XCTContext.runActivity(named: "Verify card '\(name)' is not displayed") { _ in
            let nameButton = app.buttons
                .matching(identifier: TangemPayAccessibilityIdentifiers.cardNameEditButton)
                .matching(NSPredicate(format: "label CONTAINS %@", name))
                .firstMatch
            XCTAssertTrue(
                nameButton.waitForNonExistence(timeout: .networkRequest),
                "Card '\(name)' should not be displayed in card management"
            )
            return self
        }
    }

    @discardableResult
    func verifyReplacingInProgress() -> Self {
        XCTContext.runActivity(named: "Verify 'Replacing your digital card' state") { _ in
            waitAndAssertTrue(
                app.staticTexts[Localization.tangempayReissueCardInProgress].firstMatch,
                "'Replacing your digital card' should be displayed while reissue is in progress"
            )
            return self
        }
    }

    @discardableResult
    func verifyIssuingInProgress() -> Self {
        XCTContext.runActivity(named: "Verify 'Issuing a new digital card' state on the card screen") { _ in
            waitAndAssertTrue(
                cardIssuingMessage,
                timeout: .networkRequest,
                "Issuing message should be displayed while the card is being issued"
            )
            waitAndAssertTrue(app.staticTexts[Localization.tangempayIssuingNewDigitalCardTitle].firstMatch, "Issuing title should be displayed")
            waitAndAssertTrue(app.staticTexts[Localization.tangempayReissueCardInProgressDescription].firstMatch, "Issuing description should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyPlasticDeliveryState(email: String) -> Self {
        XCTContext.runActivity(named: "Verify the plastic card delivery state") { _ in
            let message = app.staticTexts
                .matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, Localization.tangempayCardDetailsDeliveryDescription(email)))
                .matching(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, email))
                .firstMatch
            waitAndAssertTrue(message, timeout: .networkRequest, "Plastic delivery message with '\(email)' should be displayed")
            waitAndAssertTrue(plasticContactSupportButton, "Contact support should be displayed for the plastic card")
            XCTAssertTrue(plasticContactSupportButton.waitForState(state: .hittable, for: .networkRequest), "Contact support should be available")
            XCTAssertTrue(plasticActivateButton.waitForState(state: .hittable, for: .networkRequest), "Activate card should be available")
            return self
        }
    }

    @discardableResult
    func tapActivatePlasticCard() -> TangemPayActivateCardScreen {
        XCTContext.runActivity(named: "Tap Activate card on the plastic card screen") { _ in
            plasticActivateButton.waitAndTap()
            return TangemPayActivateCardScreen(app).waitForScreen()
        }
    }

    @discardableResult
    func verifyPlasticActivating() -> Self {
        XCTContext.runActivity(named: "Verify the plastic card is being activated") { _ in
            waitAndAssertTrue(
                app.staticTexts[Localization.tangempayCardPageActivatingBannerTitle].firstMatch,
                timeout: .networkRequest,
                "'\(Localization.tangempayCardPageActivatingBannerTitle)' should be displayed"
            )
            return self
        }
    }

    @discardableResult
    func waitForPlasticCardActivated() -> Self {
        XCTContext.runActivity(named: "Wait for the plastic card to be activated") { _ in
            waitAndAssertTrue(changePinRow, timeout: .robustUIUpdate, "Card actions should be displayed once the plastic card is activated")
            XCTAssertTrue(plasticActivateButton.waitForNonExistence(timeout: .conditional), "Activate card should be gone once the plastic card is activated")
            return self
        }
    }

    @discardableResult
    func tapReplacePlasticCard() -> TangemPayPlasticReissueSheet {
        XCTContext.runActivity(named: "Open Replace card for the plastic card") { _ in
            openReplaceCardFromMoreMenu()
            return TangemPayPlasticReissueSheet(app).waitForSheet()
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
                .element(matching: NSPredicate(format: "label CONTAINS %@", Localization.commonSomethingWentWrong))
                .firstMatch
            XCTAssertTrue(title.exists, "Alert title 'Something went wrong' should be displayed")

            let message = alert.staticTexts
                .element(matching: NSPredicate(format: "label CONTAINS %@", Localization.tangempayReissueCardFeeUnreachableErrorTitle))
                .firstMatch
            XCTAssertTrue(message.exists, "Alert message 'Replacement fee info unreachable' should be displayed")

            alert.buttons[Localization.commonOk].waitAndTap()
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

    @discardableResult
    func verifyRequisites() -> Self {
        XCTContext.runActivity(named: "Verify revealed card requisites") { _ in
            waitAndAssertTrue(cardNumberValue, timeout: .networkRequest, "Card number value should be displayed")
            waitAndAssertTrue(cardExpirationValue, "Card expiration value should be displayed")
            waitAndAssertTrue(cardCvcValue, "Card CVC value should be displayed")
            XCTAssertTrue(cardNumberValue.label.contains("4242 4242 4242"), "Card number should contain the mock PAN prefix")
            XCTAssertEqual(cardExpirationValue.label, "12/28", "Card expiration should match the mock value")
            XCTAssertEqual(cardCvcValue.label, "123", "Card CVC should match the mock value")
            waitAndAssertTrue(hideDetailsButton, "Hide details button should be displayed while requisites are revealed")
            return self
        }
    }

    @discardableResult
    func verifyApplePayGuideBannerVisible() -> Self {
        XCTContext.runActivity(named: "Verify Apple/Google Pay banner is displayed on card details") { _ in
            waitAndAssertTrue(
                applePayGuideBanner,
                timeout: .networkRequest,
                "Apple/Google Pay banner should be displayed on card details screen"
            )
            return self
        }
    }

    @discardableResult
    func verifyApplePayGuideBannerHidden() -> Self {
        XCTContext.runActivity(named: "Verify Apple/Google Pay banner is not displayed on card details") { _ in
            XCTAssertTrue(
                applePayGuideBanner.waitForNonExistence(timeout: .robustUIUpdate),
                "Apple/Google Pay banner should not be displayed on card details screen"
            )
            return self
        }
    }

    @discardableResult
    func closeApplePayGuideBanner() -> Self {
        XCTContext.runActivity(named: "Close Apple/Google Pay banner on card details") { _ in
            applePayGuideBannerCloseButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapApplePayGuideBanner() -> TangemPayAddToAppPayGuideScreen {
        XCTContext.runActivity(named: "Tap Apple/Google Pay instruction banner") { _ in
            applePayGuideBanner.waitAndTap()
            return TangemPayAddToAppPayGuideScreen(app)
        }
    }

    @discardableResult
    func waitForRequisitesHiddenOnCard() -> Self {
        XCTContext.runActivity(named: "Wait for card requisites to auto-hide on the card") { _ in
            XCTAssertTrue(
                hideDetailsButton.waitForNonExistence(timeout: .robustUIUpdate),
                "Hide details button should disappear once the card returns to the front"
            )
            XCTAssertTrue(
                cardNumberValue.waitForNonExistence(timeout: .robustUIUpdate),
                "Card requisites should not be displayed once the card returns to the front"
            )
            return self
        }
    }

    @discardableResult
    func verifyCardDetailsErrorToast() -> Self {
        XCTContext.runActivity(named: "Verify card details load error toast") { _ in
            let toast = app.staticTexts
                .matching(NSPredicate(format: "label CONTAINS %@", Localization.tangempayCardDetailsErrorText))
                .firstMatch
            waitAndAssertTrue(toast, "Card details load error toast should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyFreezeErrorToast() -> Self {
        XCTContext.runActivity(named: "Verify freeze failure toast") { _ in
            let toast = app.staticTexts
                .matching(NSPredicate(format: "label CONTAINS %@", Localization.tangemPayFreezeCardFailed))
                .firstMatch
            waitAndAssertTrue(toast, "Freeze failure toast should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyUnfreezeErrorToast() -> Self {
        XCTContext.runActivity(named: "Verify unfreeze failure toast") { _ in
            let toast = app.staticTexts
                .matching(NSPredicate(format: "label CONTAINS %@", Localization.tangemPayUnfreezeCardFailed))
                .firstMatch
            waitAndAssertTrue(toast, "Unfreeze failure toast should be displayed")
            return self
        }
    }

    private func openReplaceCardFromMoreMenu() {
        moreMenuButton.waitAndTap()
        replaceCardMenuItem.waitAndTap()
    }
}

enum TangemPayCardDetailsScreenElement: String, UIElement {
    case cardNameEditButton
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
    case plasticContactSupportButton
    case plasticActivateCardButton

    var accessibilityIdentifier: String {
        switch self {
        case .cardNameEditButton:
            TangemPayAccessibilityIdentifiers.cardNameEditButton
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
        case .plasticContactSupportButton:
            TangemPayAccessibilityIdentifiers.plasticContactSupportButton
        case .plasticActivateCardButton:
            TangemPayAccessibilityIdentifiers.plasticActivateCardButton
        }
    }
}

private extension TangemPayCardDetailsScreen {
    enum Constants {
        static let currencySymbol = "$"
    }
}
