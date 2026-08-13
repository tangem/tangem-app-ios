//
//  MobileOnboardingICloudBackupStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

final class MobileOnboardingICloudBackupStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingICloudBackupViewModel

    init(userWalletModel: UserWalletModel, delegate: MobileOnboardingICloudBackupDelegate) {
        viewModel = MobileOnboardingICloudBackupViewModel(
            userWalletModel: userWalletModel,
            delegate: delegate
        )
    }

    override func makeView() -> any View {
        MobileOnboardingICloudBackupView(viewModel: viewModel)
    }
}
