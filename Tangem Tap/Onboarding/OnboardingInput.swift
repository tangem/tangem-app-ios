//
//  OnboardingInput.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit

struct OnboardingInput {
    let steps: OnboardingSteps
    let cardModel: CardViewModel
    let cardImage: UIImage?
    let cardsPosition: (dark: AnimatedViewSettings, light: AnimatedViewSettings)?
    let welcomeStep: WelcomeStep?
    
    var currentStepIndex: Int
    var successCallback: (() -> Void)?
    
    var isStandalone = false
}
