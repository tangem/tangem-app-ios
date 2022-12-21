//
//  SingleCardOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum SingleCardOnboardingStep: CaseIterable, Equatable {
    case welcome
    case createWallet
    case topup
    case successTopup
    case saveUserWallet
    case success

    func cardBackgroundOffset(containerSize: CGSize) -> CGSize {
        switch self {
        case .createWallet:
            return .init(width: 0, height: containerSize.height * 0.103)
        case .topup, .successTopup:
            return defaultBackgroundOffset(in: containerSize)
//            let height = 0.112 * containerSize.height
//            return .init(width: 0, height: height)
        default:
            return .zero
        }
    }

    var balanceStackOpacity: Double {
        switch self {
        case .welcome, .createWallet, .saveUserWallet, .success: return 0
        case .topup, .successTopup: return 1
        }
    }

    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .welcome, .saveUserWallet, .success: return .zero
        case .createWallet:
            let diameter = SingleCardOnboardingCardsLayout.main.frame(for: self, containerSize: containerSize).height * 1.317
            return .init(width: diameter, height: diameter)
        case .topup, .successTopup:
            return defaultBackgroundFrameSize(in: containerSize)
//            let height = 0.61 * containerSize.height
//            return .init(width: containerSize.width * 0.787, height: height)
        }
    }

    func cardBackgroundCornerRadius(containerSize: CGSize) -> CGFloat {
        switch self {
        case .welcome, .saveUserWallet, .success: return 0
        case .createWallet: return cardBackgroundFrame(containerSize: containerSize).height / 2
        case .topup, .successTopup: return 8
        }
    }
}

extension SingleCardOnboardingStep: SuccessStep {}

extension SingleCardOnboardingStep: OnboardingMessagesProvider {
    var title: LocalizedStringKey? {
        switch self {
        case .welcome: return WelcomeStep.welcome.title
        case .createWallet: return "onboarding_create_wallet_button_create_wallet"
        case .topup: return "onboarding_topup_title"
        case .saveUserWallet: return nil
        case .successTopup: return "onboarding_done_header"
        case .success: return successTitle
        }
    }

    var subtitle: LocalizedStringKey? {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .createWallet: return "onboarding_create_wallet_body"
        case .topup: return "onboarding_top_up_body"
        case .saveUserWallet: return nil
        case .successTopup: return "onboarding_done_body"
        case .success: return "onboarding_done_body"
        }
    }

    var messagesOffset: CGSize {
        return .zero
//        switch self {
//        case .success: return successMessagesOffset
//        default: return .zero
        //       }
    }
}

extension SingleCardOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: LocalizedStringKey {
        switch self {
        case .createWallet: return "onboarding_create_wallet_button_create_wallet"
        case .topup: return "onboarding_top_up_button_but_crypto"
        case .successTopup: return "common_continue"
        case .welcome: return WelcomeStep.welcome.mainButtonTitle
        case .saveUserWallet: return BiometricAuthorizationUtils.allowButtonLocalizationKey
        case .success: return successButtonTitle
        }
    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .welcome, .topup: return true
        case .successTopup, .success, .createWallet, .saveUserWallet: return false
        }
    }

    var supplementButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.supplementButtonTitle
        case .createWallet: return "onboarding_button_what_does_it_mean"
        case .topup: return "onboarding_top_up_button_show_wallet_address"
        case .successTopup, .saveUserWallet, .success: return ""
        }
    }

    var checkmarkText: LocalizedStringKey? {
        return nil
    }

    var infoText: LocalizedStringKey? {
        switch self {
        case .saveUserWallet:
            return "save_user_wallet_agreement_notice"
        default:
            return nil
        }
    }
}

extension SingleCardOnboardingStep: OnboardingProgressStepIndicatable {
    var isOnboardingFinished: Bool {
        switch self {
        case .success, .successTopup: return true
        default: return false
        }
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

extension SingleCardOnboardingStep: OnboardingInitialStepInfo {
    static var initialStep: SingleCardOnboardingStep { .welcome }
}

extension SingleCardOnboardingStep: OnboardingTopupBalanceLayoutCalculator { }

