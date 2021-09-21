//
//  SingleCardOnboardingStep.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum SingleCardOnboardingStep: CaseIterable {
    case welcome, createWallet, topup, confetti, goToMain
    
    var hasProgressStep: Bool {
        switch self {
        case .createWallet, .topup: return true
        case .welcome, .confetti, .goToMain: return false
        }
    }
    
    var icon: Image? {
        switch self {
        case .createWallet: return Image("onboarding.create.wallet")
        case .topup: return Image("onboarding.topup")
        case .welcome, .confetti, .goToMain: return nil
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
        case .topup, .confetti:
            return defaultBackgroundOffset(in: containerSize)
//            let height = 0.112 * containerSize.height
//            return .init(width: 0, height: height)
        default:
            return .zero
        }
    }
    
    func balanceTextOffset(containerSize: CGSize) -> CGSize {
        switch self {
        case .topup, .confetti:
            let backgroundOffset = cardBackgroundFrame(containerSize: containerSize)
            return .init(width: backgroundOffset.width, height: backgroundOffset.height + 12)
        default:
            return cardBackgroundOffset(containerSize: containerSize)
        }
    }
    
    var balanceStackOpacity: Double {
        switch self {
        case .welcome, .createWallet, .goToMain: return 0
        case .topup, .confetti: return 1
        }
    }
    
    func cardBackgroundFrame(containerSize: CGSize) -> CGSize {
        switch self {
        case .welcome, .goToMain: return .zero
        case .createWallet:
            let diameter = SingleCardOnboardingCardsLayout.main.frame(for: self, containerSize: containerSize).height * 1.317
            return .init(width: diameter, height: diameter)
        case .topup, .confetti:
            return defaultBackgroundFrameSize(in: containerSize)
//            let height = 0.61 * containerSize.height
//            return .init(width: containerSize.width * 0.787, height: height)
        }
    }
    
    func cardBackgroundCornerRadius(containerSize: CGSize) -> CGFloat {
        switch self {
        case .welcome, .goToMain: return 0
        case .createWallet: return cardBackgroundFrame(containerSize: containerSize).height / 2
        case .topup, .confetti: return 8
        }
    }
}

extension SingleCardOnboardingStep: OnboardingMessagesProvider {
    var title: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.title
        case .goToMain: return ""
        case .createWallet: return "onboarding_create_title"
        case .topup: return "onboarding_topup_title"
        case .confetti: return "onboarding_confetti_title"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.subtitle
        case .goToMain: return ""
        case .createWallet: return "onboarding_create_subtitle"
        case .topup: return "onboarding_topup_subtitle"
        case .confetti: return "onboarding_confetti_subtitle"
        }
    }
}

extension SingleCardOnboardingStep: OnboardingButtonsInfoProvider {
    var mainButtonTitle: LocalizedStringKey {
        switch self {
        case .createWallet: return "onboarding_button_create_wallet"
        case .topup: return "onboarding_button_buy_crypto"
        case .confetti: return "common_continue"
        case .goToMain: return ""
        case .welcome: return WelcomeStep.welcome.mainButtonTitle
        }
    }
    
    var isSupplementButtonVisible: Bool {
        switch self {
        case .welcome, .createWallet, .topup: return true
        case .confetti, .goToMain: return false
        }
    }
    
    var supplementButtonTitle: LocalizedStringKey {
        switch self {
        case .welcome: return WelcomeStep.welcome.supplementButtonTitle
        case .createWallet: return "onboarding_button_how_it_works"
        case .topup: return "onboarding_button_show_address_qr"
        case .confetti, .goToMain: return ""
        }
    }
    
    var isContainSupplementButton: Bool {
        true
    }
}

extension SingleCardOnboardingStep: OnboardingProgressStepIndicatable {
    static func maxNumberOfSteps(isNote: Bool) -> Int {
        isNote ?
            self.allCases.count :
            2   // Old cards has 2 steps - read card and create wallet.
    }
    
    static var maxNumberOfSteps: Int {
        self.allCases.count
    }
    
    /// Use this steps for progress bar. First step is always Read card.
    var progressStep: Int {
        switch self {
        case .welcome: return 1
        case .createWallet: return 2
        case .topup: return 3
        case .confetti: return 4
        case .goToMain: return 5
        }
    }
    
    var isOnboardingFinished: Bool {
        self == .goToMain
    }
}

extension SingleCardOnboardingStep: OnboardingInitialStepInfo {
    static var initialStep: SingleCardOnboardingStep { .welcome }
}

extension SingleCardOnboardingStep: OnboardingTopupBalanceLayoutCalculator { }

