//
//  CreateBackupScreen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers
import TangemLocalization

final class CreateBackupScreen: ScreenBase<CreateBackupScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var description = staticText(.description)
    private lazy var startScanButton = button(.startScanButton)

    @discardableResult
    func validateScreen() -> Self {
        XCTContext.runActivity(named: "Validate CreateBackupScreen is displayed") { _ in
            waitAndAssertTrue(
                title,
                "Title should be displayed"
            )

            waitAndAssertTrue(
                description,
                "Description should be displayed"
            )

            XCTAssertTrue(startScanButton.isHittable)

            XCTAssertEqual(
                startScanButton.label,
                "Scan primary card or ring",
                "Start scan button should have correct text"
            )
        }
        return self
    }
}

enum CreateBackupScreenElement: String, UIElement {
    case title
    case description
    case startScanButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return OnboardingAccessibilityIdentifiers.title
        case .description:
            return OnboardingAccessibilityIdentifiers.description
        case .startScanButton:
            return OnboardingAccessibilityIdentifiers.supplementButton
        }
    }
}
