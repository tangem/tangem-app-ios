//
//  VisaOnboardingViewModelBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

struct VisaOnboardingViewModelBuilder {
    func makeOnboardingViewModel(onboardingInput: OnboardingInput, coordinator: VisaOnboardingRoutable) -> VisaOnboardingViewModel {
        let visaActivationManager: VisaActivationManager
        switch onboardingInput.cardInput {
        case .cardId:
            fatalError("Invalid card input for Visa onboarding")
        case .cardInfo(let cardInfo):
            switch cardInfo.walletData {
            case .visa(let activationStatus):
                if let activationInput = activationStatus.activationInput {
                    visaActivationManager = VisaActivationManagerFactory().make(
                        cardInput: activationInput,
                        tangemSdk: TangemSdkDefaultFactory().makeTangemSdk(),
                        urlSessionConfiguration: .default,
                        logger: AppLog.shared
                    )
                } else {
                    visaActivationManager = ActivatedVisaCardDummyManager()
                }
            default:
                fatalError("Invalid card input for Visa onboarding")
            }
        case .userWalletModel(let userWalletModel):
            // [REDACTED_TODO_COMMENT]
            fatalError("Invalid onboarding input for Visa")
        }
        let model = VisaOnboardingViewModel(
            input: onboardingInput,
            visaActivationManager: visaActivationManager,
            coordinator: coordinator
        )

        return model
    }
}
