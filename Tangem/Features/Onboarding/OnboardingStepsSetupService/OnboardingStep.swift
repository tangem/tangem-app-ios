//
//  OnboardingStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

enum OnboardingSteps {
    case singleWallet([SingleCardOnboardingStep])
    case twins([TwinsOnboardingStep])
    case wallet([WalletOnboardingStep])
    case visa([VisaOnboardingStep])

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
        case .visa(let steps):
            return steps.count
        }
    }
}

typealias OnboardingStep = OnboardingMessagesProvider & OnboardingButtonsInfoProvider & Equatable

protocol OnboardingMessagesProvider {
    var title: String? { get }
    var subtitle: String? { get }
}

protocol OnboardingButtonsInfoProvider {
    var mainButtonTitle: String { get }
    var mainButtonIcon: ImageType? { get }
    var supplementButtonTitle: String { get }
    var supplementButtonIcon: ImageType? { get }
}

extension OnboardingButtonsInfoProvider {
    var supplementButtonIcon: ImageType? { nil }
}
