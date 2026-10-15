//
//  TangemPayOrderCardTypeScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayOrderCardTypeScreen: ScreenBase<TangemPayOrderCardTypeScreenElement> {
    private lazy var selectButton = button(.selectButton)
    private lazy var virtualTab = button(.virtualTab)
    private lazy var plasticTab = button(.plasticTab)
    private lazy var basicBackground = image(.basicBackground)
    private lazy var plusBackground = image(.plusBackground)
    private lazy var title = app.staticTexts[Localization.tangempayOrderTypeTitle].firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Order card type screen") { _ in
            waitAndAssertTrue(selectButton, timeout: .networkRequest, "Select button should be displayed on Order card type screen")
            return self
        }
    }

    /// Virtual is the preselected type, so selecting it only takes confirming the screen.
    @discardableResult
    func selectVirtual() -> TangemPayIssueAdditionalCardSheet {
        XCTContext.runActivity(named: "Select the virtual card type") { _ in
            selectButton.waitAndTap()
            return TangemPayIssueAdditionalCardSheet(app)
        }
    }

    @discardableResult
    func verifyHeader() -> Self {
        XCTContext.runActivity(named: "Verify the Order new card header") { _ in
            waitAndAssertTrue(title, "'\(Localization.tangempayOrderTypeTitle)' header should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyPlusBackground() -> Self {
        XCTContext.runActivity(named: "Verify the Plus tariff background") { _ in
            waitAndAssertTrue(plusBackground, "Plus tariff background should be displayed")
            XCTAssertFalse(basicBackground.exists, "Basic tariff background should not be displayed for Plus")
            return self
        }
    }

    @discardableResult
    func verifyBasicBackground() -> Self {
        XCTContext.runActivity(named: "Verify the Basic tariff background") { _ in
            waitAndAssertTrue(basicBackground, "Basic tariff background should be displayed")
            XCTAssertFalse(plusBackground.exists, "Plus tariff background should not be displayed for Basic")
            return self
        }
    }

    @discardableResult
    func verifyVirtualTabSelected() -> Self {
        XCTContext.runActivity(named: "Verify the Virtual tab is selected") { _ in
            verifySelected(virtualTab, name: "Virtual")
            return self
        }
    }

    @discardableResult
    func selectPlasticTab() -> Self {
        XCTContext.runActivity(named: "Switch to the Plastic tab") { _ in
            plasticTab.waitAndTap()
            verifySelected(plasticTab, name: "Plastic")
            waitAndAssertTrue(offerInfoRow(.deliverTo), "Deliver to row should be displayed on the Plastic tab")
            return self
        }
    }

    @discardableResult
    func verifyPlasticTabLabel() -> Self {
        XCTContext.runActivity(named: "Verify the Plastic tab is marked Beta") { _ in
            waitAndAssertTrue(plasticTab, "Plastic tab should be displayed")
            XCTAssertTrue(plasticTab.label.contains(Localization.tangempayOrderTypeSegmentPlastic), "Plastic tab should read '\(Localization.tangempayOrderTypeSegmentPlastic)'")
            XCTAssertTrue(plasticTab.label.contains(Localization.tangempayOrderTypeBeta), "Plastic tab should carry the '\(Localization.tangempayOrderTypeBeta)' counter")
            return self
        }
    }

    @discardableResult
    func verifyVirtualOffer(issueFee: String) -> Self {
        XCTContext.runActivity(named: "Verify the virtual offer") { _ in
            verifyOfferInfoRow(.issueFee, contains: [Localization.tangempayOrderTypeIssueFee, issueFee])
            verifyOfferInfoRow(.issueTime, contains: [Localization.tangempayOrderTypeDeliveryTime, Localization.tangempayOrderTypeDeliveryTimeInstant])
            return self
        }
    }

    @discardableResult
    func verifyPlasticOffer(country: String, deliveryFee: String, deliveryTime: String) -> Self {
        XCTContext.runActivity(named: "Verify the plastic offer") { _ in
            verifyOfferInfoRow(.deliverTo, contains: [Localization.tangempayOrderTypeDeliveryTo, country, Localization.tangempayOrderTypeCountryOfResidence])
            verifyOfferInfoRow(.deliveryFee, contains: [Localization.tangempayOrderTypeDeliveryFee, deliveryFee])
            verifyOfferInfoRow(.deliveryTime, contains: [Localization.tangempayOrderTypeDeliveryTime, deliveryTime])
            return self
        }
    }

    @discardableResult
    func verifyFirstDeliveryFree() -> Self {
        XCTContext.runActivity(named: "Verify the first plastic delivery is free") { _ in
            verifyOfferInfoRow(.deliveryFee, contains: [Localization.tangempayOrderTypeFirstDeliveryFree])
            return self
        }
    }

    @discardableResult
    func verifyNoFirstDeliveryFree() -> Self {
        XCTContext.runActivity(named: "Verify the first-delivery-free badge is absent") { _ in
            verifyOfferInfoRow(.deliveryFee, doesNotContain: Localization.tangempayOrderTypeFirstDeliveryFree)
            return self
        }
    }

    @discardableResult
    func verifyNotEnoughMoney(deliveryFee: String) -> Self {
        XCTContext.runActivity(named: "Verify the balance does not cover the delivery fee") { _ in
            verifyOfferInfoRow(.deliveryFee, contains: [deliveryFee, Localization.tangempayOrderTypeNotEnoughMoney])
            return self
        }
    }

    @discardableResult
    func verifyEnoughMoney(deliveryFee: String) -> Self {
        XCTContext.runActivity(named: "Verify the balance covers the delivery fee") { _ in
            verifyOfferInfoRow(.deliveryFee, contains: [deliveryFee])
            verifyOfferInfoRow(.deliveryFee, doesNotContain: Localization.tangempayOrderTypeNotEnoughMoney)
            return self
        }
    }

    @discardableResult
    func verifyPlasticUnavailable(country: String) -> Self {
        XCTContext.runActivity(named: "Verify the plastic card is unavailable") { _ in
            verifyOfferInfoRow(.deliverTo, contains: [country, Localization.tangempayOrderTypeUnavailable])
            verifyOfferInfoRow(.deliveryFee, contains: [Constants.unknownValue])
            verifyOfferInfoRow(.deliveryTime, contains: [Constants.unknownValue])
            return self
        }
    }

    @discardableResult
    func verifySelectEnabled() -> Self {
        XCTContext.runActivity(named: "Verify Select is enabled") { _ in
            waitAndAssertTrue(selectButton, "Select button should be displayed")
            XCTAssertTrue(selectButton.waitForState(state: .enabled, for: .conditional), "Select button should be enabled")
            return self
        }
    }

    @discardableResult
    func verifySelectDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Select is disabled") { _ in
            waitAndAssertTrue(selectButton, "Select button should be displayed")
            XCTAssertTrue(selectButton.waitForState(state: .disabled, for: .conditional), "Select button should be disabled")
            return self
        }
    }

    @discardableResult
    func tapSelectPlastic() -> TangemPayOrderCardDataScreen {
        XCTContext.runActivity(named: "Select the plastic card type") { _ in
            selectButton.waitAndTap()
            return TangemPayOrderCardDataScreen(app).waitForScreen()
        }
    }

    @discardableResult
    func close() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Close the Order card type screen") { _ in
            guard let closeButton = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonClose)).firstHittableElement() else {
                XCTFail("Close button should become hittable")
                return TangemPayMainScreen(app)
            }
            closeButton.tap()
            XCTAssertTrue(selectButton.waitForNonExistence(timeout: .conditional), "Order card type screen should be closed")
            return TangemPayMainScreen(app)
        }
    }

    private func verifySelected(_ tab: XCUIElement, name: String) {
        waitAndAssertTrue(tab, "\(name) tab should be displayed")
        XCTAssertTrue(
            tab.waitForState(state: .selected, for: .conditional),
            "\(name) tab should be selected"
        )
    }
}

enum TangemPayOrderCardTypeScreenElement: String, UIElement {
    case selectButton
    case virtualTab
    case plasticTab
    case basicBackground
    case plusBackground

    var accessibilityIdentifier: String {
        switch self {
        case .selectButton:
            TangemPayAccessibilityIdentifiers.orderCardTypeSelectButton
        case .virtualTab:
            TangemPayAccessibilityIdentifiers.orderCardTab("virtual")
        case .plasticTab:
            TangemPayAccessibilityIdentifiers.orderCardTab("plastic")
        case .basicBackground:
            TangemPayAccessibilityIdentifiers.orderCardBackgroundBasic
        case .plusBackground:
            TangemPayAccessibilityIdentifiers.orderCardBackgroundPlus
        }
    }
}

private extension TangemPayOrderCardTypeScreen {
    enum Constants {
        static let unknownValue = "—"
    }
}
