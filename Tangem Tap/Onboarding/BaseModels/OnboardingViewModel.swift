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
    weak var userPrefsService: UserPrefsService?
    
    let navbarSize: CGSize = .init(width: UIScreen.main.bounds.width, height: 44)
    let resetAnimDuration: Double = 0.3
    
    @Published var steps: [Step] = []
    @Published var currentStepIndex: Int = 0
    @Published var isMainButtonBusy: Bool = false
    @Published var shouldFireConfetti: Bool = false
    @Published var isInitialAnimPlayed = false
    @Published var mainCardSettings: AnimatedViewSettings = .zero
    @Published var supplementCardSettings: AnimatedViewSettings = .zero
    @Published var isNavBarVisible: Bool = false
    @Published var alert: AlertBinder?
    
    var currentStep: Step {
        if currentStepIndex >= steps.count {
            return Step.initialStep
        }
        
        return steps[currentStepIndex]
    }
    
    var currentProgress: CGFloat {
        CGFloat(currentStep.progressStep) / CGFloat(Step.maxNumberOfSteps)
    }
    
    var navbarTitle: LocalizedStringKey {
        "onboarding_getting_started"
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
    
    var mainButtonSettings: TangemButtonSettings {
        .init(
            title: mainButtonTitle,
            size: .wide,
            action: mainButtonAction,
            isBusy: isMainButtonBusy,
            isEnabled: true,
            isVisible: true,
            color: .green
        )
    }
    
    var mainButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomeStep = input.welcomeStep {
            return welcomeStep.mainButtonTitle
        }
        
        return currentStep.mainButtonTitle
    }
    
    var supplementButtonSettings: TangemButtonSettings? {
        .init(
            title: supplementButtonTitle,
            size: .wide,
            action: supplementButtonAction,
            isBusy: false,
            isEnabled: true,
            isVisible: isSupplementButtonVisible,
            color: .transparentWhite
        )
    }
    
    var supplementButtonTitle: LocalizedStringKey {
        if !isInitialAnimPlayed, let welcomteStep = input.welcomeStep {
            return welcomteStep.supplementButtonTitle
        }
        
        return currentStep.supplementButtonTitle
    }
    
    var isBackButtonVisible: Bool {
        if !isInitialAnimPlayed || isFromMain {
            return false
        }
        
        if currentStep.isOnboardingFinished {
            return false
        }
        
        return true
    }
    
    var isBackButtonEnabled: Bool {
        true
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
            isNavBarVisible = true
        }
    }
    
    func setupContainer(with size: CGSize) {
        let isInitialSetup = containerSize == .zero
        containerSize = size
        if isFromMain,
           isInitialAnimPlayed {
            setupCardsSettings(animated: !isInitialSetup, isContainerSetup: true)
        }
    }
    
    func playInitialAnim(includeInInitialAnim: (() -> Void)? = nil) {
        let animated = !isFromMain
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(animated ? .default : nil) {
                self.isInitialAnimPlayed = true
                self.isNavBarVisible = true
                self.setupCardsSettings(animated: animated, isContainerSetup: false)
                includeInInitialAnim?()
            }
        }
    }
    
    func goToNextStep() {
        if currentStep.isOnboardingFinished, !assembly.isPreview {
            DispatchQueue.main.async {
                self.successCallback?()
            }
            
            let cardId = input.cardModel.cardInfo.card.cardId
            if let existingIndex = userPrefsService?.cardsStartedActivation.firstIndex(where: { $0 == cardId }) {
                userPrefsService?.cardsStartedActivation.remove(at: existingIndex)
            }
            
            return
        }
        
        var newIndex = currentStepIndex + 1
        if newIndex >= steps.count {
            newIndex = assembly.isPreview ? 0 : steps.count - 1
        }
        
        withAnimation {
            currentStepIndex = newIndex
            
            setupCardsSettings(animated: true, isContainerSetup: false)
        }
    }
    
    func reset(includeInResetAnim: (() -> Void)? = nil) {
        let defaultSettings = WelcomeCardLayout.defaultSettings(in: containerSize, animated: true)
        var newSteps = [Step.initialStep]
        if assembly.isPreview {
            newSteps.append(contentsOf: steps)
        }
        withAnimation(.easeIn(duration: resetAnimDuration)) {
            mainCardSettings = defaultSettings.main
            supplementCardSettings = defaultSettings.supplement
            isNavBarVisible = false
            currentStepIndex = 0
            steps = newSteps
            isMainButtonBusy = false
            includeInResetAnim?()
        }
        // [REDACTED_TODO_COMMENT]
        DispatchQueue.main.asyncAfter(deadline: .now() + resetAnimDuration) {
            self.navigation.onboardingReset = true
        }
    }
    
    func mainButtonAction() {
        fatalError("Not implemented")
    }
    
    func supplementButtonAction() {
        fatalError("Not implemented")
    }
    
    func setupCardsSettings(animated: Bool, isContainerSetup: Bool) {
        fatalError("Not implemented")
    }
    
}
