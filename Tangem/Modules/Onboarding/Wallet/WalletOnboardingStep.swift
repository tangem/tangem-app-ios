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
    case kycRetry
    case kycProgress
    case kycWaiting
    case claim
    case successClaim

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
        case .kycStart, .kycProgress, .kycWaiting, .kycRetry:
            return "onboarding_navbar_kyc_progress"
        case .claim, .successClaim:
            return "onboarding_navbar_claim"
        }
    }

    static var resumeBackupSteps: [WalletOnboardingStep] {
        [.backupCards, .success]
    }

    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .welcome, .success, .backupCards:
            return .zero
        case .claim, .successClaim:
            return defaultBackgroundFrameSize(in: containerSize)
        default:
            let cardFrame = WalletOnboardingCardLayout.origin.frame(for: self, containerSize: containerSize)
            let diameter = cardFrame.height * 1.242
            return .init(width: diameter, height: diameter)
        }
    }

    func cardBackgroundCornerRadius(containerSize: CGSize) -> CGFloat {
        switch self {
        case .welcome, .success, .backupCards: return 0
        case .claim, .successClaim: return 8
        default: return cardBackgroundFrame(containerSize: containerSize).height / 2
        }
    }

    func backgroundOffset(in container: CGSize) -> CGSize {
        switch self {
        case .claim, .successClaim:
            return defaultBackgroundOffset(in: container)
        default:
            let cardOffset = WalletOnboardingCardLayout.origin.offset(at: .createWallet, in: container)
            return cardOffset
        }
    }

    var balanceStackOpacity: Double {
        switch self {
        case .claim, .successClaim: return 1
        default: return 0
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
        case .success, .successClaim: return successTitle
        case .registerWallet:
            return "onboarding_title_register_wallet"
        case .kycStart:
            return "onboarding_title_kyc_start"
        case .kycRetry:
            return "onboarding_title_kyc_retry"
        case .kycWaiting:
            return "onboarding_title_kyc_waiting"
        case .enterPin:
            return "onboarding_title_pin"
        case .claim:
            return ""
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
        case .kycRetry:
            return "onboarding_subtitle_kyc_retry"
        case .kycWaiting:
            return "onboarding_subtitle_kyc_waiting"
        case .enterPin:
            return "onboarding_subtitle_pin"
        case .claim:
            return "onboarding_subtitle_claim"
        case .successClaim:
            return "onboarding_subtitle_success_claim"
        }
    }

    var messagesOffset: CGSize {
        switch self {
        case .success, .claim, .successClaim: return CGSize(width: 0, height: -2)
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
        case .kycWaiting: return "onboarding_supplement_button_kyc_waiting"
        default: return ""
        }
    }

    var supplementButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.supplementButtonTitle
        case .createWallet: return "onboarding_button_how_it_works"
        case .backupIntro: return "onboarding_button_skip_backup"
        case .selectBackupCards: return "onboarding_button_finalize_backup"
        case .kycWaiting: return  "onboarding_button_kyc_waiting"
        case .enterPin: return "onboarding_button_pin"
        case .registerWallet:  return "onboarding_button_register_wallet"
        case .kycStart, .kycRetry:  return "onboarding_button_kyc_start"
        case .claim: return "onboarding_button_claim"
        case .successClaim: return "onboarding_button_continue_wallet"
        default: return ""
        }

    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .scanPrimaryCard, .backupCards, .success, .createWallet: return false
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
        self == .success ||  self == .successClaim
    }

    var successCircleOpacity: Double {
        self == .success ? 1.0 : 0.0
    }

    var successCircleState: OnboardingCircleButton.State {
        switch self {
        case .success: return .doneCheckmark
        default: return .blank
        }
    }
}

extension WalletOnboardingStep: OnboardingTopupBalanceLayoutCalculator { }
