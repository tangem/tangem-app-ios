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

typealias OnboardingStep = OnboardingProgressStepIndicatable & OnboardingMessagesProvider & OnboardingButtonsInfoProvider & Equatable

protocol OnboardingMessagesProvider {
    var title: String? { get }
    var subtitle: String? { get }
    var messagesOffset: CGSize { get }
}

protocol OnboardingButtonsInfoProvider {
    var mainButtonTitle: String { get }
    var mainButtonIcon: ImageType? { get }
    var supplementButtonTitle: String { get }
    var supplementButtonIcon: ImageType? { get }
    var checkmarkText: String? { get }
    var infoText: String? { get }
}

extension OnboardingButtonsInfoProvider {
    var supplementButtonIcon: ImageType? { nil }
}
