//
//  WalletOnboardingStep.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum WalletOnboardingStep {
    case welcome, createWallet, scanOriginCard, backupIntro, selectBackupCards, backupCards, success
    
    var navbarTitle: LocalizedStringKey {
        switch self {
        case .welcome: return ""
        case .createWallet, .backupIntro: return "onboarding_getting_started"
        case .scanOriginCard, .selectBackupCards: return "onboarding_navbar_title_creating_backup"
        case .backupCards: return "common_finalize"
        case .success: return "common_done"
        }
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
    var title: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.title
        case .createWallet: return "onboarding_button_create_wallet"
        case .scanOriginCard: return "onboarding_title_scan_origin_card"
        case .backupIntro: return "onboarding_title_backup_card"
        case .selectBackupCards: return "onboarding_title_no_backup_cards"
        case .backupCards: return "onboarding_title_backup_card \(1)"
        case .success: return successTitle
        }
        
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .createWallet: return "onboarding_create_subtitle"
        case .scanOriginCard: return "onboarding_subtitle_scan_origin_card"
        case .backupIntro: return "onboarding_subtitle_backup_card"
        case .selectBackupCards: return "onboarding_subtitle_no_backup_cards"
        case .backupCards: return "onboarding_subtitle_backup_warning"
        case .success: return "onboarding_subtitle_success_backup"
        }
        
    }
    
    var messagesOffset: CGSize {
        .zero
    }
    
    
}

extension WalletOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.mainButtonTitle
        case .createWallet: return "wallet_button_create_wallet"
        case .scanOriginCard: return "onboarding_button_scan_origin_card"
        case .backupIntro: return "onboarding_button_backup_now"
        case .selectBackupCards: return "onboarding_button_add_backup_card"
        case .backupCards: return ""
        case .success: return "common_continue"
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
        case .scanOriginCard, .backupCards, .success: return false
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
    static var maxNumberOfSteps: Int {
        6
    }
    
    var progressStep: Int {
        switch self {
        case .welcome: return 0
        case .createWallet: return 1
        case .scanOriginCard: return 3
        case .backupIntro: return 2
        case .selectBackupCards: return 4
        case .backupCards: return 5
        case .success: return 6
        }
    }
    
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
