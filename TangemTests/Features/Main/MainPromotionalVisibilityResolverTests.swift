//
//  MainPromotionalVisibilityResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Main promotional visibility resolver")
struct MainPromotionalVisibilityResolverTests {
    private let resolver = MainPromotionalVisibilityResolver()

    @Test("Resolves the promotional visibility from the system cards on Main", arguments: Scenario.allCases)
    func resolve(scenario: Scenario) {
        let visibility = resolver.resolve(
            systemNotifications: scenario.events.map(makeInput),
            hasOtherSystemContent: scenario.hasOtherSystemContent
        )

        #expect(visibility == scenario.expected)
    }
}

// MARK: - Scenarios

extension MainPromotionalVisibilityResolverTests {
    enum Scenario: CaseIterable {
        case noSystemCards
        case devCardOnly
        case devCardAndRateApp
        case addFundsOnly
        case addFundsAndMissingBackup
        case addFundsAndOtherSystemContent

        var events: [GeneralNotificationEvent] {
            switch self {
            case .noSystemCards: []
            case .devCardOnly: [.devCard]
            case .devCardAndRateApp: [.devCard, .rateApp]
            case .addFundsOnly, .addFundsAndOtherSystemContent: [.addFunds]
            case .addFundsAndMissingBackup: [.missingBackup, .addFunds]
            }
        }

        var hasOtherSystemContent: Bool {
            self == .addFundsAndOtherSystemContent
        }

        var expected: MainPromotionalVisibility {
            switch self {
            case .noSystemCards, .devCardOnly: .all
            case .addFundsOnly: .tangemPayPromoOnly
            case .devCardAndRateApp, .addFundsAndMissingBackup, .addFundsAndOtherSystemContent: .hidden
            }
        }
    }
}

// MARK: - Helpers

private extension MainPromotionalVisibilityResolverTests {
    func makeInput(for event: GeneralNotificationEvent) -> NotificationViewInput {
        NotificationsFactory().buildNotificationInput(
            for: event,
            action: { _ in },
            buttonAction: { _, _ in },
            dismissAction: { _ in }
        )
    }
}
