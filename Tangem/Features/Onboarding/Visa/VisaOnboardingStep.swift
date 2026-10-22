//
//  VisaOnboardingStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemLocalization

enum VisaOnboardingStep: Equatable {
    case welcome
    case welcomeBack(isAccessCodeSet: Bool)
    case accessCode

    case paymentAccountDeployInProgress
    case pinSelection
    case issuerProcessingInProgress

    case saveUserWallet
    case pushNotifications

    case success

    var navigationTitle: String {
        switch self {
        case .welcome, .welcomeBack:
            return Localization.onboardingGettingStarted
        case .accessCode:
            return Localization.onboardingWalletInfoTitleThird
        case .paymentAccountDeployInProgress, .issuerProcessingInProgress:
            return Localization.commonInProgress
        case .pinSelection:
            return "PIN code"
        case .saveUserWallet:
            return Localization.onboardingNavbarSaveWallet
        case .pushNotifications:
            return Localization.onboardingTitleNotifications
        case .success:
            return Localization.commonDone
        }
    }
}
