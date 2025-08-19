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

    func validate() {
        XCTContext.runActivity(named: "Validate Referral Screen") { _ in
            XCTAssertTrue(title.waitForExistence(timeout: .robustUIUpdate))
            XCTAssertTrue(currenciesSection.exists, "Currencies section elements should exist")
            XCTAssertTrue(discountSection.exists, "Discount section elements should exist")
            XCTAssertTrue(participateButton.exists, "Participate button should exist")
            XCTAssertTrue(tosButton.exists, "TOS button should exist")
        }
    }
}

enum ReferralScreenElement: String, UIElement {
    case title
    case participateButton
    case tosButton
    case currenciesSection
    case discountSection

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
        }
    }
}
