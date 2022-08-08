//
//  OnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk

class OnboardingViewModel<Step: OnboardingStep> {
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
    @Published var cardImage: UIImage?

    private var confettiFired: Bool = false
    var bag: Set<AnyCancellable> = []

    var currentStep: Step {
        if currentStepIndex >= steps.count {
            return Step.initialStep
        }

        return steps[currentStepIndex]
    }

    var currentProgress: CGFloat {
        CGFloat(currentStepIndex + 1) / CGFloat(input.steps.stepsCount)
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

    var isOnboardingFinished: Bool {
        currentStep.isOnboardingFinished
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

        if isOnboardingFinished {
            return false
        }

        return true
    }

    var isBackButtonEnabled: Bool {
        true
    }

    var isSupplementButtonVisible: Bool { currentStep.isSupplementButtonVisible }

    let input: OnboardingInput

    var isFromMain: Bool = false
    private(set) var containerSize: CGSize = .zero
    unowned let onboardingCoordinator: OnboardingRoutable

    init(input: OnboardingInput, onboardingCoordinator: OnboardingRoutable) {
        self.input = input
        self.onboardingCoordinator = onboardingCoordinator
        isFromMain = input.isStandalone
        isNavBarVisible = input.isStandalone

        input.cardInput.cardModel.map { loadImage(for: $0) }
    }

    private func loadImage(for cardModel: CardViewModel) {
        cardModel
            .imageLoaderPublisher
            .sink { [weak self] image in
                withAnimation {
                    self?.cardImage = image
                }
            }
            .store(in: &bag)
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

    func onOnboardingFinished(for cardId: String) {
        if let existingIndex = AppSettings.shared.cardsStartedActivation.firstIndex(where: { $0 == cardId }) {
            AppSettings.shared.cardsStartedActivation.remove(at: existingIndex)
        }
    }

    func backButtonAction() {}

    func fireConfetti() {
        if !confettiFired {
            shouldFireConfetti = true
            confettiFired = true
        }
    }

    func goToNextStep() {
        if isOnboardingFinished {
            DispatchQueue.main.async {
                self.closeOnboarding()
            }

            onOnboardingFinished(for: input.cardInput.cardId)
            return
        }

        var newIndex = currentStepIndex + 1
        if newIndex >= steps.count {
            newIndex = steps.count - 1
        }

        withAnimation {
            currentStepIndex = newIndex

            setupCardsSettings(animated: true, isContainerSetup: false)
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

// MARK: - Navigation
extension OnboardingViewModel {
    func closeOnboarding() {
        onboardingCoordinator.closeOnboarding()
    }

    func popToRoot() {
        onboardingCoordinator.popToRoot()
    }
}
