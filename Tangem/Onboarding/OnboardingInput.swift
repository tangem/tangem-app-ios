//
//  OnboardingInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit
import TangemSdk

struct OnboardingInput {
    let steps: OnboardingSteps
    let cardInput: CardInput
    let cardsPosition: (dark: AnimatedViewSettings, light: AnimatedViewSettings)?
    let welcomeStep: WelcomeStep?
    
    var currentStepIndex: Int
    var successCallback: (() -> Void)?
    
    var isStandalone = false
}

extension OnboardingInput {
    enum CardInput {
        case cardModel(_ cardModel: CardViewModel)
        case cardId(_ cardId: String)
        
        var cardModel: CardViewModel? {
            switch self {
            case .cardModel(let cardModel):
                return cardModel
            default:
                return nil
            }
        }
        
        var cardId: String {
            switch self {
            case .cardModel(let cardModel):
                return cardModel.cardInfo.card.cardId
            case .cardId(let cardId):
                return cardId
            }
        }
    }
}
