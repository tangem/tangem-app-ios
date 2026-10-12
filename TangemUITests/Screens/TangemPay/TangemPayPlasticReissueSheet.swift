//
//  TangemPayPlasticReissueSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayPlasticReissueSheet: ScreenBase<TangemPayPlasticReissueSheetElement> {
    private lazy var icon = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.popupIcon].firstMatch
    private lazy var replaceButton = button(.replaceButton)
    private lazy var cancelButton = button(.cancelButton)

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the Replace plastic card sheet") { _ in
            waitAndAssertTrue(replaceButton, timeout: .networkRequest, "Replace card button should be displayed on the plastic reissue sheet")
            return self
        }
    }

    @discardableResult
    func verifyContent(country: String, deliveryFee: String, deliveryTime: String) -> Self {
        XCTContext.runActivity(named: "Verify the Replace plastic card sheet content") { _ in
            waitAndAssertTrue(icon, "Replace icon should be displayed")
            waitAndAssertTrue(app.staticTexts[Constants.title].firstMatch, "'\(Constants.title)' should be displayed")
            waitAndAssertTrue(app.staticTexts[Constants.description].firstMatch, "Replace plastic card description should be displayed")
            verifyOfferInfoRow(.deliverTo, contains: [Constants.deliverToTitle, country])
            verifyOfferInfoRow(.deliveryFee, contains: [Constants.deliveryFeeTitle, deliveryFee])
            verifyOfferInfoRow(.deliveryTime, contains: [Constants.deliveryTimeTitle, deliveryTime])
            XCTAssertEqual(cancelButton.label, Constants.cancelTitle, "Secondary button should read '\(Constants.cancelTitle)'")
            XCTAssertEqual(replaceButton.label, Constants.replaceTitle, "Primary button should read '\(Constants.replaceTitle)'")
            return self
        }
    }

    @discardableResult
    func verifyNotEnoughMoney(deliveryFee: String) -> Self {
        XCTContext.runActivity(named: "Verify the balance does not cover the replacement") { _ in
            verifyOfferInfoRow(.deliveryFee, contains: [deliveryFee, Constants.notEnoughMoney])
            XCTAssertTrue(replaceButton.waitForState(state: .disabled, for: .conditional), "Replace card should be disabled")
            return self
        }
    }

    @discardableResult
    func verifyEnoughMoney(deliveryFee: String) -> Self {
        XCTContext.runActivity(named: "Verify the balance covers the replacement") { _ in
            verifyOfferInfoRow(.deliveryFee, contains: [deliveryFee])
            verifyOfferInfoRow(.deliveryFee, doesNotContain: Constants.notEnoughMoney)
            XCTAssertTrue(replaceButton.waitForState(state: .enabled, for: .conditional), "Replace card should be enabled")
            return self
        }
    }

    @discardableResult
    func tapCancel() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap Cancel on the Replace plastic card sheet") { _ in
            cancelButton.waitAndTap()
            XCTAssertTrue(replaceButton.waitForNonExistence(timeout: .conditional), "Replace plastic card sheet should be dismissed")
            return TangemPayCardDetailsScreen(app)
        }
    }

    @discardableResult
    func tapReplace() -> TangemPayOrderCardDataScreen {
        XCTContext.runActivity(named: "Tap Replace card") { _ in
            replaceButton.waitAndTap()
            return TangemPayOrderCardDataScreen(app).waitForScreen()
        }
    }
}

enum TangemPayPlasticReissueSheetElement: String, UIElement {
    case replaceButton
    case cancelButton

    var accessibilityIdentifier: String {
        switch self {
        case .replaceButton:
            TangemPayAccessibilityIdentifiers.plasticReissueSheetConfirmButton
        case .cancelButton:
            TangemPayAccessibilityIdentifiers.popupSecondaryButton
        }
    }
}

private extension TangemPayPlasticReissueSheet {
    enum Constants {
        static let title = "Replace plastic card?"
        static let description = "Your current plastic card will be immediately closed. You will get new plastic card with new card details."
        static let deliverToTitle = "Deliver to"
        static let deliveryFeeTitle = "Delivery fee"
        static let deliveryTimeTitle = "Delivery time"
        static let notEnoughMoney = "Not enough money"
        static let cancelTitle = "Cancel"
        static let replaceTitle = "Replace card"
    }
}
