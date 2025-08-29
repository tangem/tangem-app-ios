//
//  SingleCardOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

enum SingleCardOnboardingStep: Equatable {
    case pushNotifications
    case createWallet
    case saveUserWallet
    case addTokens
    case success

    var navbarTitle: String {
        switch self {
        case .pushNotifications:
            return Localization.onboardingTitleNotifications
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
        default:
            return .zero
        }
    }

    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .pushNotifications, .saveUserWallet, .addTokens, .success: return .zero
        case .createWallet:
            let diameter = SingleCardOnboardingCardsLayout.main.frame(for: self, containerSize: containerSize).height * 1.317
            return .init(width: diameter, height: diameter)
        }
    }
}

extension SingleCardOnboardingStep: SuccessStep {}

extension SingleCardOnboardingStep: OnboardingMessagesProvider {
    var title: String? {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
        case .success: return successTitle
        case .saveUserWallet, .pushNotifications, .addTokens: return nil
        }
    }

    var subtitle: String? {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletBody
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

    var isSupplementButtonVisible: Bool { false }

    var supplementButtonTitle: String {
        switch self {
        case .createWallet: return Localization.onboardingCreateWalletButtonCreateWallet
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
        case .success:
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
