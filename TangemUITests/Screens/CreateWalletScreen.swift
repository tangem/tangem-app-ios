//
//  CreateWalletScreen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers
import TangemLocalization

final class CreateWalletScreen: ScreenBase<CreateWalletScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var description = staticText(.description)
    private lazy var mainButton = button(.mainButton)
    private lazy var supplementButton = button(.supplementButton)

    @discardableResult
    func validateScreen(by card: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Validate CreateWalletScreen is displayed") { _ in
            waitAndAssertTrue(
                title,
                "Title should be displayed"
            )

            waitAndAssertTrue(
                description,
                "Description should be displayed"
            )

            waitAndAssertTrue(
                supplementButton,
                "Continue button should be displayed"
            )

            XCTAssertTrue(supplementButton.isHittable)

            if card == .wallet2NoWallets {
                XCTAssertEqual(mainButton.label, "Create wallet")

                XCTAssertEqual(supplementButton.label, "Other options")
            } else if card == .shibaNoWallets {
                XCTAssertEqual(supplementButton.label, "Create wallet")
            }
        }
        return self
    }
}

enum CreateWalletScreenElement: String, UIElement {
    case title
    case description
    case mainButton
    case supplementButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return OnboardingAccessibilityIdentifiers.title
        case .description:
            return OnboardingAccessibilityIdentifiers.description
        case .mainButton:
            return OnboardingAccessibilityIdentifiers.mainButton
        case .supplementButton:
            return OnboardingAccessibilityIdentifiers.supplementButton
        }
    }
}
