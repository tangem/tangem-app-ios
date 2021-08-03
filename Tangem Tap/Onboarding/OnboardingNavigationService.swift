//
//  OnboardingNavigationService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum OnboardingStep: Int, CaseIterable {
    case read, disclaimer, createWallet, topup, confetti
}

class OnboardingNavigationService {
    
    weak var userPrefs: UserPrefsService!
    
    func steps(for card: Card) -> [OnboardingStep] {
        var steps: [OnboardingStep] = []
        
        if !userPrefs.isTermsOfServiceAccepted {
            steps.append(.disclaimer)
        }
        
        if card.wallets.count == 0 {
            steps.append(.createWallet)
        }
        
        if card.isTangemNote {
            steps.append(.topup)
        }
        
        if steps.count > 0 {
            steps.insert(.read, at: 0)
            steps.append(.confetti)
        }
        
        return steps
    }
    
}
