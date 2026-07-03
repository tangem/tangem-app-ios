//
//  ReferralScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class ReferralScreen: ScreenBase<ReferralScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var participateButton = button(.participateButton)
    private lazy var tosButton = button(.tosButton)
    private lazy var currenciesSection = staticText(.currenciesSection)
    private lazy var discountSection = staticText(.discountSection)
    private lazy var promoCodeTitle = staticText(.promoCodeTitle)
    private lazy var promoCodeValue = staticText(.promoCodeValue)

    func verifyReferralScreenDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Referral Screen") { _ in
            XCTAssertTrue(title.waitForExistence(timeout: .robustUIUpdate))
            XCTAssertTrue(currenciesSection.exists, "Currencies section elements should exist")
            XCTAssertTrue(discountSection.exists, "Discount section elements should exist")
            XCTAssertTrue(participateButton.exists, "Participate button should exist")
            XCTAssertTrue(tosButton.exists, "TOS button should exist")
            return self
        }
    }

    @discardableResult
    func verifyPersonalCodeTitleDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate 'Your personal code' title is displayed") { _ in
            waitAndAssertTrue(promoCodeTitle, "'Your personal code' title should be displayed")
            return self
        }
    }

    @discardableResult
    func tapParticipateButton() -> Self {
        XCTContext.runActivity(named: "Click on 'Participate' button") { _ in
            XCTAssert(participateButton.waitForExistence(timeout: .conditional))
            participateButton.tap()
            return self
        }
    }
}

enum ReferralScreenElement: String, UIElement {
    case title
    case participateButton
    case tosButton
    case currenciesSection
    case discountSection
    case promoCodeTitle
    case promoCodeValue

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return ReferralAccessibilityIdentifiers.title
        case .participateButton:
            return ReferralAccessibilityIdentifiers.participateButton
        case .tosButton:
            return ReferralAccessibilityIdentifiers.tosButton
        case .currenciesSection:
            return ReferralAccessibilityIdentifiers.currenciesSection
        case .discountSection:
            return ReferralAccessibilityIdentifiers.discountSection
        case .promoCodeTitle:
            return ReferralAccessibilityIdentifiers.promoCodeTitle
        case .promoCodeValue:
            return ReferralAccessibilityIdentifiers.promoCodeValue
        }
    }
}
