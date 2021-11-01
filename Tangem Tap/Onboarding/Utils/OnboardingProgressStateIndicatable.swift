//
//  OnboardingProgressStateIndicatable.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingProgressStepIndicatable {
    var isOnboardingFinished: Bool { get }
    var successCircleOpacity: Double { get }
    var successCircleState: OnboardingCircleButton.State { get }
}
