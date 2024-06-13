//
//  SingleCardOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum SingleCardOnboardingStep: Equatable {
    case pushNotifications
    case createWallet
    case topup
    case successTopup
    case saveUserWallet
    case addTokens
    case success

    var navbarTitle: String {
        switch self {
        case .pushNotifications:
            return "Push Notifications" // [REDACTED_TODO_COMMENT]
        case .addTokens:
            return Localization.onboardingAddTokens
        default:
            return Localization.onboardingTitle
        }
    }

    func cardBackgroundOffset(containerSize: CGSize) -> CGSize {
        switch self {
        case .createWallet, .addTokens:
            return .init(width: 0, height: containerSize.height * 0.103)
        case .topup, .successTopup:
            return defaultBackgroundOffset(in: containerSize)
        default:
            return .zero
        }
    }

    var balanceStackOpacity: Double {
        switch self {
        case .pushNotifications, .createWallet, .saveUserWallet, .addTokens, .success: return 0
        case .topup, .successTopup: return 1
        }
    }

    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .pushNotifications, .saveUserWallet, .addTokens, .success: return .zero
        case .createWallet:
            let diameter = SingleCardOnboardingCardsLayout.main.frame(for: self, containerSize: containerSize).height * 1.317
            return .init(width: diameter, height: diameter)
        case .topup, .successTopup:
            return defaultBackgroundFrameSize(in: containerSize)
        }
    }

    func cardBackgroundCornerRadius(containerSize: CGSize) -> CGFloat {
        switch self {
        case .pushNotifications, .saveUserWallet, .addTokens, .success: return 0
        case .createWallet: return cardBackgroundFrame(containerSize: containerSize).height / 2
        case .topup, .successTopup: return 8
        }
    }
}

extension SingleCardOnboardingStep: SuccessStep {}

extension SingleCardOnboardingStep: OnboardingMessagesProvider {
    var title: String? {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .topup: return Localization.onboardingTopupTitle
        case .successTopup: return Localization.onboardingDoneHeader
        case .success: return successTitle
        case .saveUserWallet, .pushNotifications, .addTokens: return nil
        }
    }

    var subtitle: String? {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletBody
        case .topup: return Localization.onboardingTopUpBody
        case .successTopup: return Localization.onboardingDoneBody
        case .success: return Localization.onboardingDoneBody
        case .saveUserWallet, .pushNotifications, .addTokens: return nil
        }
    }

    var messagesOffset: CGSize {
        return .zero
    }
}

extension SingleCardOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: String {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .topup: return Localization.onboardingTopUpButtonButCrypto
        case .successTopup: return Localization.commonContinue
        case .success: return successButtonTitle
        case .pushNotifications, .addTokens, .saveUserWallet: return ""
        }
    }

    var mainButtonIcon: ImageType? {
        switch self {
        case .createWallet:
            return Assets.tangemIcon
        default:
            return nil
        }
    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .topup: return true
        case .successTopup, .success, .createWallet, .saveUserWallet, .addTokens, .pushNotifications: return false
        }
    }

    var supplementButtonTitle: String {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .topup: return Localization.onboardingTopUpButtonShowWalletAddress
        case .successTopup: return Localization.commonContinue
        case .success: return successButtonTitle
        case .saveUserWallet, .addTokens, .pushNotifications: return ""
        }
    }

    var supplementButtonIcon: ImageType? {
        switch self {
        case .createWallet: return Assets.tangemIcon
        default: return nil
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

extension SingleCardOnboardingStep: OnboardingTopupBalanceLayoutCalculator {}
