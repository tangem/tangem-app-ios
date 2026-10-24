//
//  CollectiblesOnboardingError.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum CollectiblesOnboardingError: Error {
    case coldKeyNotDerived
    case stateUnresolved
    case stepDidNotAdvance(CollectiblesOnboardingInteractor.OnboardingStep)
}
