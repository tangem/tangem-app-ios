//
//  OnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps
    func buildBackupSteps() -> OnboardingSteps?
}

extension OnboardingStepsBuilder {
    var shouldAddSaveUserWalletStep: Bool {
        BiometricsUtil.isAvailable && !AppSettings.shared.saveUserWallets && !AppSettings.shared.askedToSaveUserWallets
    }
}
