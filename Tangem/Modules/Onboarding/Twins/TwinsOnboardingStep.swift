//
//  TwinsOnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

protocol SuccessStep {
    var successTitle: String { get }
    var successButtonTitle: String { get }
    var successMessagesOffset: CGSize { get }
}

extension SuccessStep {
    var successTitle: String { L10n.onboardingDoneHeader }
    var successButtonTitle: String { L10n.commonContinue }
    var successMessagesOffset: CGSize {
        .init(width: 0, height: -UIScreen.main.bounds.size.height * 0.115)
    }
}

enum TwinsOnboardingStep: Equatable {
    case welcome
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

    func backgroundFrame(in container: CGSize) -> CGSize {
        switch self {
        case .topup,  .done:
            return defaultBackgroundFrameSize(in: container)
        case .welcome:
            return .zero
        default: return .init(width: 10, height: 10)
        }
    }

    func backgroundCornerRadius(in container: CGSize) -> CGFloat {
        switch self {
        case .topup,  .done: return defaultBackgroundCornerRadius
        case .welcome: return 0
        default: return backgroundFrame(in: container).height / 2
        }
    }

    func backgroundOffset(in container: CGSize) -> CGSize {
        defaultBackgroundOffset(in: container)
    }

    var backgroundOpacity: Double {
        switch self {
        case .topup,  .done: return 1
        default: return 0
        }
    }
}

extension TwinsOnboardingStep: OnboardingProgressStepIndicatable {
    var isOnboardingFinished: Bool {
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
        case .welcome: return WelcomeStep.welcome.title
        case .intro: return L10n.twinsOnboardingSubtitle
        case .first, .third: return String(stringLiteral: L10n.twinsRecreateTitleFormat("1"))
        case .second: return String(stringLiteral: L10n.twinsRecreateTitleFormat("2"))
        case .topup: return L10n.onboardingTopupTitle
        case .done: return L10n.onboardingDoneHeader
        case .saveUserWallet: return nil
        case .success: return successTitle
        case .alert: return L10n.commonWarning
        }
    }

    var subtitle: String? {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .intro(let pairNumber): return String(stringLiteral: L10n.twinsOnboardingDescriptionFormat(pairNumber))
        case .first, .second, .third: return L10n.onboardingTwinsInterruptWarning
        case .topup: return L10n.onboardingTopUpBody
        case .saveUserWallet: return nil
        case .done, .success: return L10n.onboardingDoneBody
        case .alert: return L10n.twinsRecreateWarning
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
        case .welcome: return WelcomeStep.welcome.mainButtonTitle
        case .intro: return L10n.commonContinue
        case .first, .third: return String(stringLiteral: L10n.twinsRecreateButtonFormat("1"))
        case .second: return String(stringLiteral: L10n.twinsRecreateButtonFormat("2"))
        case .topup: return L10n.onboardingTopUpButtonButCrypto
        case .done: return L10n.commonContinue
        case .saveUserWallet: return BiometricAuthorizationUtils.allowButtonLocalizationKey
        case .success: return successButtonTitle
        case .alert: return L10n.commonContinue
        }
    }

    var supplementButtonTitle: String {
        switch self {
        case .welcome: return WelcomeStep.welcome.supplementButtonTitle
        case .topup: return L10n.onboardingTopUpButtonShowWalletAddress
        default: return ""
        }
    }

    var isSupplementButtonVisible: Bool {
        switch self {
        case .topup, .welcome: return true
        default: return false
        }
    }

    var isContainSupplementButton: Bool { true }

    var checkmarkText: String? {
        switch self {
        case .alert:
            return L10n.commonUnderstand
        default:
            return nil
        }
    }

    var infoText: String? {
        switch self {
        case .saveUserWallet:
            return L10n.saveUserWalletAgreementNotice
        default:
            return nil
        }
    }
}

extension TwinsOnboardingStep: OnboardingInitialStepInfo {
    static var initialStep: TwinsOnboardingStep { .welcome }
    static var finalStep: TwinsOnboardingStep { .done }
}
