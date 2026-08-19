//
//  JointAccountOnboardingViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class JointAccountOnboardingViewModel: ObservableObject {
    private weak var coordinator: JointAccountOnboardingRoutable?

    init(coordinator: JointAccountOnboardingRoutable?) {
        self.coordinator = coordinator
    }

    func onContinueTap() {
        coordinator?.continueOnboarding()
    }

    func onCloseTap() {
        coordinator?.closeOnboarding()
    }
}
