//
//  TwinsOnboardingStep.swift
//  Tangem
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

protocol SuccessStep {
    var successTitle: LocalizedStringKey { get }
    var successButtonTitle: LocalizedStringKey { get }
    var successMessagesOffset: CGSize { get }
}

extension SuccessStep {
    var successTitle: LocalizedStringKey { "onboarding_success" }
    var successButtonTitle: LocalizedStringKey { "common_continue" }
    var successMessagesOffset: CGSize {
        .init(width: 0, height: -UIScreen.main.bounds.size.height * 0.115)
    }
}

enum TwinsOnboardingStep {
    case welcome, intro(pairNumber: String), first, second, third, topup, done, success, alert
    
    static var previewCases: [TwinsOnboardingStep] {
        [.intro(pairNumber: "2"), .topup, .done]
    }
    
    static var twinningProcessSteps: [TwinsOnboardingStep] {
        [.first, .second, .third]
    }
    
    static var topupSteps: [TwinsOnboardingStep] {
        [.topup, .done]
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
    var title: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.title
        case .intro: return "twins_onboarding_subtitle"
        case .first: return "onboarding_title_twin_first_card"
        case .second: return "onboarding_title_twin_second_card"
        case .third: return "onboarding_title_twin_first_card"
        case .topup: return "onboarding_topup_title"
        case .done: return "onboarding_confetti_title"
        case .success: return successTitle
        case .alert: return "common_warning"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .intro(let pairNumber): return LocalizedStringKey(stringLiteral: "onboarding_subtitle_intro".localized(pairNumber))
        case .first, .second, .third: return "onboarding_subtitle_reset_twin_warning"
        case .topup: return "onboarding_topup_subtitle"
        case .done, .success: return "onboarding_success_subtitle"
        case .alert: return "onboarding_alert_twins_recreate_subtitle"
        }
    }
    
    var messagesOffset: CGSize {
        switch self {
        default: return .zero
        }
    }
}

extension TwinsOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.mainButtonTitle
        case .intro: return "common_continue"
        case .first, .third: return "onboarding_button_tap_first_card"
        case .second: return "onboarding_button_tap_second_card"
        case .topup: return "onboarding_button_buy_crypto"
        case .done: return "common_continue"
        case .success: return successButtonTitle
        case .alert: return "common_continue"
        }
    }
    
    var supplementButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.supplementButtonTitle
        case .topup: return "onboarding_button_show_address_qr"
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
    
    var checkmarkText: LocalizedStringKey? {
        switch self {
        case .alert:
            return "onboarding_alert_i_understand"
        default:
            return nil
        }
    }
}

extension TwinsOnboardingStep: OnboardingInitialStepInfo {
    static var initialStep: TwinsOnboardingStep { .welcome }
    static var finalStep: TwinsOnboardingStep { .done }
}
