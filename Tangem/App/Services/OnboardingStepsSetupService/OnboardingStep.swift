//
//  OnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

enum OnboardingSteps {
    case singleWallet([SingleCardOnboardingStep])
    case twins([TwinsOnboardingStep])
    case wallet([WalletOnboardingStep])

    var needOnboarding: Bool {
        stepsCount > 0
    }

    var stepsCount: Int {
        switch self {
        case .singleWallet(let steps):
            return steps.count
        case .twins(let steps):
            return steps.count
        case .wallet(let steps):
            return steps.count
        }
    }
}

typealias OnboardingStep = OnboardingProgressStepIndicatable & OnboardingMessagesProvider & OnboardingButtonsInfoProvider & OnboardingInitialStepInfo & Equatable

protocol OnboardingMessagesProvider {
    var title: LocalizedStringKey? { get }
    var subtitle: LocalizedStringKey? { get }
    var messagesOffset: CGSize { get }
}

protocol OnboardingButtonsInfoProvider {
    var mainButtonTitle: LocalizedStringKey { get }
    var supplementButtonTitle: LocalizedStringKey { get }
    var isSupplementButtonVisible: Bool { get }
    var checkmarkText: LocalizedStringKey? { get }
    var infoText: LocalizedStringKey? { get }
}

protocol OnboardingInitialStepInfo {
    static var initialStep: Self { get }
}
