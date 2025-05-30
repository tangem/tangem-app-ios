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
        var initialActivationStatus: VisaCardActivationLocalState?
        switch onboardingInput.cardInput {
        case .cardId:
            logInvalidInput("CardId provided in onboarding input. Can't resume backup with visa card")
        case .cardInfo(let cardInfo):
            switch cardInfo.walletData {
            case .visa(let activationStatus):
                initialActivationStatus = activationStatus
            default:
                logInvalidInput("Wrong Wallet Data provided in onboarding input. \(cardInfo.walletData) provided instead of Visa wallet data")
            }
        case .userWalletModel(let userWalletModel):
            guard let config = userWalletModel.config as? VisaConfig else {
                logInvalidInput("Wrong Config provided in onboarding input. \(userWalletModel.config) provided instead of Visa config")
                break
            }

            initialActivationStatus = config.activationLocalState
        }

        let visaActivationManager: VisaActivationManager
        if let initialActivationStatus {
            let factory = VisaActivationManagerFactory(
                apiType: FeatureStorage.instance.visaAPIType,
                isTestnet: FeatureStorage.instance.visaAPIType.isTestnet,
                isMockedAPIEnabled: FeatureStorage.instance.isVisaAPIMocksEnabled
            )
            visaActivationManager = factory.make(
                cardId: onboardingInput.primaryCardId,
                initialActivationStatus: initialActivationStatus,
                tangemSdk: TangemSdkDefaultFactory().makeTangemSdk(),
                urlSessionConfiguration: .visaConfiguration
            )
        } else {
            visaActivationManager = ActivatedVisaCardDummyManager()
        }

        let model = VisaOnboardingViewModel(
            input: onboardingInput,
            visaActivationManager: visaActivationManager,
            coordinator: coordinator
        )

        return model
    }

    private func logInvalidInput(_ error: Error) {
        VisaLogger.error(
            "Invalid card input was received while creating onboarding view model",
            error: error
        )
    }
}
