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
    
    func backgroundFrameSize(in container: CGSize) -> CGSize {
        switch self {
        case .createWallet:
            let cardFrame = WalletOnboardingCardLayout.origin.frame(for: self, containerSize: container)
            let diameter = cardFrame.height * 1.242
            return .init(width: diameter, height: diameter)
        case .backupIntro:
            return .init(width: 816, height: 816)
        default:
            return .zero
        }
    }
    
    func backgroundOffset(in container: CGSize) -> CGSize {
        switch self {
        case .backupIntro:
            return .init(width: 0, height: -container.height * 0.572)
        default:
            return .init(width: 0, height: container.height * 0.089)
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
        case .success: return "onboarding_success"
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
        case .success: return successTitle
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
        case .scanOriginCard: return false
        default: return true
        }
    }
    
    var isContainSupplementButton: Bool {
        switch self {
        case .backupCards, .success: return false
        default: return true
        }
    }
    
    
}

extension WalletOnboardingStep: OnboardingInitialStepInfo {
    static var initialStep: WalletOnboardingStep {
        .welcome
    }
    
    
}

extension WalletOnboardingStep: OnboardingProgressStepIndicatable {
    static var maxNumberOfSteps: Int {
        5
    }
    
    var progressStep: Int {
        switch self {
        case .welcome: return 0
        case .createWallet: return 1
        case .scanOriginCard: return 1
        case .backupIntro: return 2
        case .selectBackupCards: return 3
        case .backupCards: return 4
        case .success: return 5
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
