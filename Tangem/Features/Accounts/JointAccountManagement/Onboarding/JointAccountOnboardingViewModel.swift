//
//  JointAccountOnboardingViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

final class JointAccountOnboardingViewModel: ObservableObject {
    /// What a joint account is, in the three points the onboarding makes before the flow starts.
    let points: [Point] = [
        Point(
            id: .members,
            icon: DesignSystem.Icons.UserPlus.regular20,
            lead: Localization.jointAccountOnboardingMembersTitle(Constants.maximumMembersCount),
            description: Localization.jointAccountOnboardingMembersDescription
        ),
        Point(
            id: .shared,
            icon: DesignSystem.Icons.Users.regular20,
            lead: Localization.jointAccountOnboardingSharedTitle,
            description: Localization.jointAccountOnboardingSharedDescription
        ),
        Point(
            id: .approvals,
            icon: DesignSystem.Icons.ShieldCheckmark.regular20,
            lead: Localization.jointAccountOnboardingApprovalsTitle,
            description: Localization.jointAccountOnboardingApprovalsDescription
        ),
    ]

    private let creationHelper: JointAccountCreationHelper
    private weak var coordinator: JointAccountOnboardingRoutable?

    init(creationHelper: JointAccountCreationHelper, coordinator: JointAccountOnboardingRoutable?) {
        self.creationHelper = creationHelper
        self.coordinator = coordinator
    }

    func onContinueTap() {
        coordinator?.continueOnboarding(creationHelper: creationHelper)
    }

    func onCloseTap() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - Auxiliary types

extension JointAccountOnboardingViewModel {
    struct Point: Identifiable {
        let id: ID
        let icon: ImageType
        /// Set off from the description, the way the sentence starts with what the point is about.
        let lead: String
        let description: String

        enum ID: String {
            case members
            case shared
            case approvals
        }
    }
}

// MARK: - Constants

private extension JointAccountOnboardingViewModel {
    enum Constants {
        /// The upper bound of the composition the next step of the flow offers.
        static let maximumMembersCount = 5
    }
}
