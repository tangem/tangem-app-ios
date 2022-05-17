//
//  OnboardingStepsSetupService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

protocol OnboardingStepsSetupService {
    func steps(for cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error>
    func twinRecreationSteps(for cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error>
    func stepsForBackupResume() -> AnyPublisher<OnboardingSteps, Error>
    func backupSteps(_ cardInfo: CardInfo) -> AnyPublisher<OnboardingSteps, Error>
}

private struct OnboardingStepsSetupServiceKey: InjectionKey {
    static var currentValue: OnboardingStepsSetupService = CommonOnboardingStepsSetupService()
}

extension InjectedValues {
    var onboardingStepsSetupService: OnboardingStepsSetupService {
        get { Self[OnboardingStepsSetupServiceKey.self] }
        set { Self[OnboardingStepsSetupServiceKey.self] = newValue }
    }
}


