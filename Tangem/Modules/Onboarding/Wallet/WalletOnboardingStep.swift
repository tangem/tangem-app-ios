//
//  WalletOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum WalletOnboardingStep {
    case welcome
    case createWallet
    case scanPrimaryCard
    case backupIntro
    case selectBackupCards
    case backupCards

    // visa only
    case enterPin
    case registerWallet
    case kycStart
    case kycProgress
    case kycWaiting

    case success

    var navbarTitle: LocalizedStringKey {
        switch self {
        case .welcome: return ""
        case .createWallet, .backupIntro: return "onboarding_getting_started"
        case .scanPrimaryCard, .selectBackupCards, .backupCards: return "onboarding_navbar_title_creating_backup"
        case .success: return "common_done"
        case .enterPin:
            return "onboarding_navbar_pin"
        case .registerWallet:
            return "onboarding_navbar_register_wallet"
        case .kycStart:
            return "onboarding_navbar_kyc_start"
        case .kycProgress:
            return "onboarding_navbar_kyc_progress"
        case .kycWaiting:
            return "onboarding_navbar_kyc_waiting"
        }
    }

    static var resumeBackupSteps: [WalletOnboardingStep] {
        [.backupCards, .success]
    }

    func backgroundFrameSize(in container: CGSize) -> CGSize {
        switch self {
        case .welcome, .success, .backupCards:
            return .zero
//        case .backupIntro:
//            return .init(width: 816, height: 816)
        default:
            let cardFrame = WalletOnboardingCardLayout.origin.frame(for: self, containerSize: container)
            let diameter = cardFrame.height * 1.242
            return .init(width: diameter, height: diameter)
        }
    }

    func backgroundOffset(in container: CGSize) -> CGSize {
        switch self {
//        case .backupIntro:
//            return .init(width: 0, height: -container.height * 0.572)
        default:
            let cardOffset = WalletOnboardingCardLayout.origin.offset(at: .createWallet, in: container)
            return cardOffset
//            return .init(width: 0, height: container.height * 0.089)
        }
    }

}

extension WalletOnboardingStep: OnboardingMessagesProvider, SuccessStep {
    var title: LocalizedStringKey? {
        switch self {
        case .welcome: return WelcomeStep.welcome.title
        case .createWallet: return "onboarding_button_create_wallet"
        case .scanPrimaryCard: return "onboarding_title_scan_origin_card"
        case .backupIntro: return "onboarding_title_backup_card"
        case .selectBackupCards: return "onboarding_title_no_backup_cards"
        case .backupCards, .kycProgress: return ""
        case .success: return successTitle
        case .registerWallet:
            return "onboarding_title_register_wallet"
        case .kycStart:
            return "onboarding_title_kyc_start"
        case .kycWaiting:
            return "onboarding_title_kyc_waiting"
        case .enterPin:
            return nil
        }
    }

    var subtitle: LocalizedStringKey? {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .createWallet: return "onboarding_create_subtitle"
        case .scanPrimaryCard: return "onboarding_subtitle_scan_primary"
        case .backupIntro: return "onboarding_subtitle_backup_card"
        case .selectBackupCards: return "onboarding_subtitle_no_backup_cards"
        case .backupCards, .kycProgress: return ""
        case .success: return "onboarding_subtitle_success_backup"
        case .registerWallet:
            return "onboarding_subtitle_register_wallet"
        case .kycStart:
            return "onboarding_subtitle_kyc_start"
        case .kycWaiting:
            return "onboarding_subtitle_kyc_waiting"
        case .enterPin:
            return nil
        }
    }

    var messagesOffset: CGSize {
        switch self {
        case .success: return CGSize(width: 0, height: -2)
        default: return .zero
        }
    }
}

extension WalletOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.mainButtonTitle
        case .createWallet: return "wallet_button_create_wallet"
        case .scanPrimaryCard: return "onboarding_button_scan_origin_card"
        case .backupIntro: return "onboarding_button_backup_now"
        case .selectBackupCards: return "onboarding_button_add_backup_card"
        case .backupCards, .kycProgress: return ""
        case .success: return "onboarding_button_continue_wallet"
        case .enterPin:
            return "onboarding_button_pin"
        case .registerWallet:
            return "onboarding_button_register_wallet"
        case .kycStart:
            return "onboarding_button_kyc_start"
        case .kycWaiting:
            return "onboarding_button_kyc_waiting"
        }
    }

    var supplementButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.supplementButtonTitle
        case .createWallet: return "onboarding_button_how_it_works"
        case .backupIntro: return "onboarding_button_skip_backup"
        case .selectBackupCards: return "onboarding_button_finalize_backup"
        default: return ""
        }

    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .scanPrimaryCard, .backupCards, .success, .createWallet,
             .enterPin, .registerWallet, .kycStart, .kycProgress, .kycWaiting: return false
        default: return true
        }
    }

    var isContainSupplementButton: Bool {
        true
    }

    var checkmarkText: LocalizedStringKey? {
        return nil
    }
}

extension WalletOnboardingStep: OnboardingInitialStepInfo {
    static var initialStep: WalletOnboardingStep {
        .welcome
    }


}

extension WalletOnboardingStep: OnboardingProgressStepIndicatable {
    var isOnboardingFinished: Bool {
        self == .success
    }

    var successCircleOpacity: Double {
        isOnboardingFinished ? 1.0 : 0.0
    }

    var successCircleState: OnboardingCircleButton.State {
        isOnboardingFinished ? .doneCheckmark : .blank
    }
}
