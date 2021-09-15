//
//  OnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class OnboardingViewModel<Step: OnboardingStep>: ViewModel {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    
    let navbarSize: CGSize = .init(width: UIScreen.main.bounds.width, height: 44)
    
    @Published var steps: [Step] = []
    @Published var currentStepIndex: Int = 0
    @Published var isMainButtonBusy: Bool = false
    @Published var shouldFireConfetti: Bool = false
    @Published var isInitialAnimPlayed = false
    @Published var mainCardSettings: AnimatedViewSettings = .zero
    @Published var supplementCardSettings: AnimatedViewSettings = .zero
    
    
    var currentStep: Step { steps[currentStepIndex] }
    
    var currentProgress: CGFloat {
        CGFloat(currentStep.progressStep) / CGFloat(Step.maxNumberOfSteps)
    }
    
    var title: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomeStep = input.welcomeStep {
            return welcomeStep.title
        }
        
        return currentStep.title
    }
    
    var subtitle: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomteStep = input.welcomeStep {
            return welcomteStep.subtitle
        }
        
        return currentStep.subtitle
    }
    
    var mainButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomeStep = input.welcomeStep {
            return welcomeStep.mainButtonTitle
        }
        
        return currentStep.mainButtonTitle
    }
    
    var supplementButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomteStep = input.welcomeStep {
            return welcomteStep.supplementButtonTitle
        }
        
        return currentStep.supplementButtonTitle
    }
    
    var isSupplementButtonVisible: Bool { currentStep.isSupplementButtonVisible }
    
    let successCallback: (() -> Void)?
    let input: OnboardingInput
    
    var isFromMain: Bool = false
    private(set) var containerSize: CGSize = .zero
    
    init(input: OnboardingInput) {
        self.input = input
        successCallback = input.successCallback
        if let cardsSettings = input.cardsPosition {
            mainCardSettings = cardsSettings.dark
            supplementCardSettings = cardsSettings.light
            isInitialAnimPlayed = false
        } else {
            isFromMain = true
            isInitialAnimPlayed = true
        }
    }
    
    func setupContainer(with size: CGSize) {
        let isInitialSetup = containerSize == .zero
        containerSize = size
        if input.welcomeStep != nil, isInitialAnimPlayed {
            setupCardsSettings(animated: !isInitialSetup)
        }
    }
    
    func playInitialAnim() {
        let animated = !isFromMain
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(animated ? .default : nil) {
                self.isInitialAnimPlayed = true
                self.setupCardsSettings(animated: animated)
            }
        }
    }
    
    func goToNextStep() {
        var newIndex = currentStepIndex + 1
        if newIndex >= steps.count {
            newIndex = assembly.isPreview ? 0 : steps.count - 1
        }
        
        if steps[newIndex].isOnboardingFinished, !assembly.isPreview {
            DispatchQueue.main.async {
                self.successCallback?()
            }
            return
        }
        
        withAnimation {
            currentStepIndex = newIndex
            
            setupCardsSettings(animated: true)
        }
    }
    
    func executeStep() {
        fatalError("Not implemented")
    }
    
    func supplementButtonAction() {
        fatalError("Not implemented")
    }
    
    func setupCardsSettings(animated: Bool) {
        fatalError("Not implemented")
    }
    
}
