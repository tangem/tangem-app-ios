//
//  TwinsOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

protocol SuccessStep {
    var successTitle: String { get }
    var successButtonTitle: String { get }
    var successMessagesOffset: CGSize { get }
}

extension SuccessStep {
    var successTitle: String { Localization.onboardingDoneHeader }
    var successButtonTitle: String { Localization.commonContinue }
    var successMessagesOffset: CGSize {
        .init(width: 0, height: -UIScreen.main.bounds.size.height * 0.115)
    }
}

enum TwinsOnboardingStep: Equatable {
    case pushNotifications
    case intro(pairNumber: String)
    case first
    case second
    case third
    case topup
    case done
    case saveUserWallet
    case success
    case alert

    static var previewCases: [TwinsOnboardingStep] {
        [.intro(pairNumber: "2"), .topup, .done]
    }

    static var twinningProcessSteps: [TwinsOnboardingStep] {
        [.first, .second, .third]
    }

    static var topupSteps: [TwinsOnboardingStep] {
        [.topup, .done]
    }

    static var twinningSteps: [TwinsOnboardingStep] {
        var steps: [TwinsOnboardingStep] = []
        steps.append(.alert)
        steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
        steps.append(.success)
        return steps
    }

    var topTwinCardIndex: Int {
        switch self {
        case .second: return 1
        default: return 0
        }
    }

    var isBackgroundVisible: Bool {
        switch self {
        case .intro: return true
        default: return false
        }
    }

    var isModal: Bool {
        switch self {
        case .second, .third: return true
        default: return false
        }
    }

    var navbarTitle: String {
        switch self {
        case .pushNotifications:
            return Localization.onboardingTitleNotifications
        default:
            return Localization.twinsRecreateToolbar
        }
    }

    func backgroundFrame(in container: CGSize) -> CGSize {
        switch self {
        case .topup, .done:
            return defaultBackgroundFrameSize(in: container)
        default: return .init(width: 10, height: 10)
        }
    }

    func backgroundCornerRadius(in container: CGSize) -> CGFloat {
        switch self {
        case .topup, .done: return defaultBackgroundCornerRadius
        default: return backgroundFrame(in: container).height / 2
        }
    }

    func backgroundOffset(in container: CGSize) -> CGSize {
        defaultBackgroundOffset(in: container)
    }

    var backgroundOpacity: Double {
        switch self {
        case .topup, .done: return 1
        default: return 0
        }
    }
}

extension TwinsOnboardingStep: OnboardingProgressStepIndicatable {
    var requiresConfetti: Bool {
        switch self {
        case .success, .done:
            return true
        default:
            return false
        }
    }

    var successCircleOpacity: Double {
        switch self {
        case .success: return 1
        default: return 0
        }
    }

    var successCircleState: OnboardingCircleButton.State {
        switch self {
        case .success: return .doneCheckmark
        default: return .blank
        }
    }
}

extension TwinsOnboardingStep: OnboardingTopupBalanceLayoutCalculator {}

extension TwinsOnboardingStep: SuccessStep {}

extension TwinsOnboardingStep: OnboardingMessagesProvider {
    var title: String? {
        switch self {
        case .intro: return Localization.twinsOnboardingSubtitle
        case .first, .third: return Localization.twinsRecreateTitleFormat("1")
        case .second: return Localization.twinsRecreateTitleFormat("2")
        case .topup: return Localization.onboardingTopupTitle
        case .done: return Localization.onboardingDoneHeader
        case .saveUserWallet, .pushNotifications: return nil
        case .success: return successTitle
        case .alert: return Localization.commonWarning
        }
    }

    var subtitle: String? {
        switch self {
        case .intro(let pairNumber): return Localization.twinsOnboardingDescriptionFormat(pairNumber)
        case .first, .second, .third: return Localization.onboardingTwinsInterruptWarning
        case .topup: return Localization.onboardingTopUpBody
        case .saveUserWallet, .pushNotifications: return nil
        case .done, .success: return Localization.onboardingDoneBody
        case .alert: return Localization.twinsRecreateWarning
        }
    }

    var messagesOffset: CGSize {
        switch self {
        default: return .zero
        }
    }
}

extension TwinsOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: String {
        switch self {
        case .topup: return Localization.onboardingTopUpButtonButCrypto
        case .saveUserWallet: return BiometricAuthorizationUtils.allowButtonTitle
        default: return ""
        }
    }

    var mainButtonIcon: ImageType? {
        switch self {
        case .first, .second, .third:
            return Assets.tangemIcon
        default:
            return nil
        }
    }

    var supplementButtonTitle: String {
        switch self {
        case .topup: return Localization.onboardingTopUpButtonShowWalletAddress
        case .first, .third: return Localization.twinsRecreateButtonFormat("1")
        case .second: return Localization.twinsRecreateButtonFormat("2")
        case .success: return successButtonTitle
        case .done, .alert, .intro: return Localization.commonContinue
        default: return ""
        }
    }

    var supplementButtonIcon: ImageType? {
        switch self {
        case .first, .second, .third:
            return Assets.tangemIcon
        default:
            return nil
        }
    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .topup: return true
        default: return false
        }
    }

    var isContainSupplementButton: Bool { true }

    var checkmarkText: String? {
        switch self {
        case .alert:
            return Localization.commonUnderstand
        default:
            return nil
        }
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
