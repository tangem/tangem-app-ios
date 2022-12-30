//
//  SingleCardOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum SingleCardOnboardingStep: Equatable {
    case welcome
    case createWallet
    case topup
    case successTopup
    case saveUserWallet
    case success

    var hasProgressStep: Bool {
        switch self {
        case .createWallet, .topup: return true
        case .welcome, .successTopup, .saveUserWallet, .success: return false
        }
    }

    var icon: Image? {
        switch self {
        case .createWallet: return Image("onboarding.create.wallet")
        case .topup: return Image("onboarding.topup")
        case .welcome, .successTopup, .saveUserWallet, .success: return nil
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

extension SingleCardOnboardingStep: SuccessStep { }

extension SingleCardOnboardingStep: OnboardingMessagesProvider {
    var title: String? {
        switch self {
        case .welcome: return WelcomeStep.welcome.title
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .topup: return Localization.onboardingTopupTitle
        case .saveUserWallet: return nil
        case .successTopup: return Localization.onboardingDoneHeader
        case .success: return successTitle
        }
    }

    var subtitle: String? {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .createWallet: return Localization.onboardingCreateWalletBody
        case .topup: return Localization.onboardingTopUpBody
        case .saveUserWallet: return nil
        case .successTopup: return Localization.onboardingDoneBody
        case .success: return Localization.onboardingDoneBody
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
    var mainButtonTitle: String {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .topup: return Localization.onboardingTopUpButtonButCrypto
        case .successTopup: return Localization.commonContinue
        case .welcome: return WelcomeStep.welcome.mainButtonTitle
        case .saveUserWallet: return BiometricAuthorizationUtils.allowButtonTitle
        case .success: return successButtonTitle
        }
    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .welcome, .topup: return true
        case .successTopup, .success, .createWallet, .saveUserWallet: return false
        }
    }

    var supplementButtonTitle: String {
        switch self {
        case .welcome: return WelcomeStep.welcome.supplementButtonTitle
        case .createWallet: return Localization.onboardingButtonWhatDoesItMean
        case .topup: return Localization.onboardingTopUpButtonShowWalletAddress
        case .successTopup, .saveUserWallet, .success: return ""
        }
    }

    var checkmarkText: String? {
        return nil
    }

    var infoText: String? {
        switch self {
        case .saveUserWallet:
            return Localization.saveUserWalletAgreementNotice
        default:
            return nil
        }
    }
}

extension SingleCardOnboardingStep: OnboardingProgressStepIndicatable {
    var requiresConfetti: Bool {
        switch self {
        case .success, .successTopup:
            return true
        default:
            return false
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

