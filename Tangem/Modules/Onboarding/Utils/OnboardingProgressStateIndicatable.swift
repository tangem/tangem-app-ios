//
//  OnboardingProgressStateIndicatable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingProgressStepIndicatable {
    var requiresConfetti: Bool { get }
    var successCircleOpacity: Double { get }
    var successCircleState: OnboardingCircleButton.State { get }
}
