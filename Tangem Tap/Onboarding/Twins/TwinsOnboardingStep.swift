//
//  TwinsOnboardingStep.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum TwinsOnboardingStep {
    case welcome, intro(pairNumber: String), first, second, third, topup, confetti, done
    
    static var previewCases: [TwinsOnboardingStep] {
        [.intro(pairNumber: "2"), .topup, .confetti, .done]
    }
    
    static var twinningProcessSteps: [TwinsOnboardingStep] {
        [.first, .second, .third]
    }
    
    static var topupSteps: [TwinsOnboardingStep] {
        [.topup, .confetti, .done]
    }
    
    var topTwinCardIndex: Int {
        switch self {
        case .second: return 1
        default: return 0
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
        case .topup, .confetti, .done:
            return defaultBackgroundFrameSize(in: container)
        case .welcome:
            return .zero
        default: return .init(width: 10, height: 10)
        }
    }
    
    func backgroundCornerRadius(in container: CGSize) -> CGFloat {
        switch self {
        case .topup, .confetti, .done: return defaultBackgroundCornerRadius
        case .welcome: return 0
        default: return backgroundFrame(in: container).height / 2
        }
    }
    
    func backgroundOffset(in container: CGSize) -> CGSize {
        defaultBackgroundOffset(in: container)
    }
    
    var backgroundOpacity: Double {
        switch self {
        case .topup, .confetti, .done: return 1
        default: return 0
        }
    }
}

extension TwinsOnboardingStep: OnboardingProgressStepIndicatable {
    var isOnboardingFinished: Bool {
        if case .done = self {
            return true
        }
        
        return false
    }
    
    static var maxNumberOfSteps: Int { 6 }
    
    var progressStep: Int {
        switch self {
        case .welcome: return 1
        case .intro, .first: return 2
        case .second: return 3
        case .third: return 4
        case .topup: return 5
        case .confetti: return 6
        case .done: return 6
        }
    }
}


extension TwinsOnboardingStep: OnboardingTopupBalanceLayoutCalculator {}

extension TwinsOnboardingStep: OnboardingMessagesProvider {
    var title: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.title
        case .intro: return "twins_onboarding_subtitle"
        case .first: return "onboarding_title_twin_first_card"
        case .second: return "onboarding_title_twin_second_card"
        case .third: return "onboarding_title_twin_first_card"
        case .topup: return "onboarding_topup_title"
        case .confetti: return "onboarding_confetti_title"
        case .done: return ""
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .intro(let pairNumber): return "onboarding_subtitle_intro \(pairNumber)"
        case .first, .second, .third: return "onboarding_subtitle_reset_twin_warning"
        case .topup: return "onboarding_topup_subtitle"
        case .confetti: return "Your crypto card is activated and ready to be used"
        case .done: return ""
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
        case .confetti: return "common_continue"
        case .done: return "common_continue"
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
}

extension TwinsOnboardingStep: OnboardingInitialStepInfo {
    static var initialStep: TwinsOnboardingStep { .welcome }
    static var finalStep: TwinsOnboardingStep { .done }
}
