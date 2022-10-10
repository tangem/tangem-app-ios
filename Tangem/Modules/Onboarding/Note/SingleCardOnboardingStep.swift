//
//  SingleCardOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum SingleCardOnboardingStep: CaseIterable {
    case welcome
    case createWallet
    case topup
    case successTopup
    case success

    var hasProgressStep: Bool {
        switch self {
        case .createWallet, .topup: return true
        case .welcome, .successTopup, .success: return false
        }
    }

    var icon: Image? {
        switch self {
        case .createWallet: return Image("onboarding.create.wallet")
        case .topup: return Image("onboarding.topup")
        case .welcome, .successTopup, .success: return nil
        }
    }

    var iconFont: Font {
        switch self {
        default: return .system(size: 20, weight: .regular)
        }
    }

    var bigCircleBackgroundScale: CGFloat {
        switch self {
        default: return 0.0
        }
    }

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

    func balanceTextOffset(containerSize: CGSize) -> CGSize {
        switch self {
        case .topup, .successTopup:
            let backgroundOffset = cardBackgroundFrame(containerSize: containerSize)
            return .init(width: backgroundOffset.width, height: backgroundOffset.height + 12)
        default:
            return cardBackgroundOffset(containerSize: containerSize)
        }
    }

    var balanceStackOpacity: Double {
        switch self {
        case .welcome, .createWallet, .success: return 0
        case .topup, .successTopup: return 1
        }
    }

    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .welcome, .success: return .zero
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
        case .welcome, .success: return 0
        case .createWallet: return cardBackgroundFrame(containerSize: containerSize).height / 2
        case .topup, .successTopup: return 8
        }
    }
}

extension SingleCardOnboardingStep: SuccessStep { }

extension SingleCardOnboardingStep: OnboardingMessagesProvider {
    var title: LocalizedStringKey? {
        switch self {
        case .welcome: return WelcomeStep.welcome.title
        case .createWallet: return "onboarding_create_title"
        case .topup: return "onboarding_topup_title"
        case .successTopup: return "onboarding_confetti_title"
        case .success: return successTitle
        }
    }

    var subtitle: LocalizedStringKey? {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .createWallet: return "onboarding_create_subtitle"
        case .topup: return "onboarding_topup_subtitle"
        case .successTopup: return "onboarding_confetti_subtitle"
        case .success: return "onboarding_confetti_subtitle"
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
        case .createWallet: return "onboarding_button_create_wallet"
        case .topup: return "onboarding_button_buy_crypto"
        case .successTopup: return "common_continue"
        case .welcome: return WelcomeStep.welcome.mainButtonTitle
        case .success: return successButtonTitle
        }
    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .welcome, .topup: return true
        case .successTopup, .success, .createWallet: return false
        }
    }

    var supplementButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.supplementButtonTitle
        case .createWallet: return "onboarding_button_how_it_works"
        case .topup: return "onboarding_button_show_address_qr"
        case .successTopup, .success: return ""
        }
    }

    var checkmarkText: LocalizedStringKey? {
        return nil
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

