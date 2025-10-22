//
//  MobileOnboardingUpgradeStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class MobileOnboardingUpgradeStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingUpgradeViewModel

    init(delegate: MobileOnboardingUpgradeDelegate) {
        viewModel = MobileOnboardingUpgradeViewModel(delegate: delegate)
    }

    override func build() -> any View {
        MobileOnboardingUpgradeView(viewModel: viewModel)
    }
}
