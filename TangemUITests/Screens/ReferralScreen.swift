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
    /// Type-agnostic: the row is composed of a button wrapper whose element type is not guaranteed.
    private lazy var addressForRewardsAccountRow = app.descendants(matching: .any)
        .matching(identifier: ReferralAccessibilityIdentifiers.addressForRewardsAccountRow)
        .firstMatch

    @discardableResult
    func verifyReferralScreenDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Referral Screen") { _ in
            waitAndAssertTrue(title, "Referral screen title should exist")
            waitAndAssertTrue(currenciesSection, "Currencies section elements should exist")
            waitAndAssertTrue(discountSection, "Discount section elements should exist")
            waitAndAssertTrue(participateButton, "Participate button should exist")
            waitAndAssertTrue(tosButton, "TOS button should exist")
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
    func openAccountSelector() -> AccountSelectorSheet {
        XCTContext.runActivity(named: "Open account selector from the 'Address for rewards' block") { _ in
            waitAndAssertTrue(addressForRewardsAccountRow, "Account row should be displayed in the 'Address for rewards' block")
            addressForRewardsAccountRow.waitAndTap()
            return AccountSelectorSheet(app)
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
