//
//  VisaOnboardingStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum VisaOnboardingStep {
    case welcome

    case saveUserWallet
    case pushNotifications

    case success

    var navigationTitle: String {
        switch self {
        case .welcome:
            return Localization.onboardingGettingStarted
        case .saveUserWallet:
            return Localization.onboardingNavbarSaveWallet
        case .pushNotifications:
            return Localization.onboardingTitleNotifications
        case .success:
            return Localization.commonDone
        }
    }
}
