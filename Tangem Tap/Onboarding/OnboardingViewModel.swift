//
//  OnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class OnboardingViewModel: ViewModel {
    
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    
    weak var cardsRepository: CardsRepository!
    weak var onboardingNaviService: OnboardingNavigationService!
    
    @Published var currentStep: OnboardingStep = .read
    
    var steps: [OnboardingStep] = [.read, .disclaimer]
    
    var shopURL: URL { URL(string: "https://shop.tangem.com/?afmc=1i&utm_campaign=1i&utm_source=leaddyno&utm_medium=affiliate")! }
    
    private var currentStepIndex: Int = 0 {
        didSet {
            if currentStepIndex >= steps.count {
                currentStepIndex = 0
            }
            
            currentStep = steps[currentStepIndex]
        }
    }

    func transitionToNextStep() {
        withAnimation {
            self.currentStepIndex += 1
        }
    }
    
    func executeStep() {
        switch currentStep {
        case .read:
            scanCard()
        default:
            break
        }
    }
    
    func scanCard() {
        cardsRepository.scan { [weak self] response in
            guard let self = self else { return }
            
            switch response {
            case .success(let result):
                guard let card = result.card else { return }
                
                self.steps = self.onboardingNaviService.steps(for: card)
            case .failure(let error):
                print(error)
            }
        }
    }
    
}
