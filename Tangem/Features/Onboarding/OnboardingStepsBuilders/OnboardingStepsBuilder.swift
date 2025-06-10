//
//  OnboardingStepsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps
    func buildBackupSteps() -> OnboardingSteps?
}
