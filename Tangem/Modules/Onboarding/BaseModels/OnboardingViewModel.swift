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

    var titleLineLimit: Int? {
        switch self {
        default:
            return 1
        }
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

    var isSkipButtonVisible: Bool {
        false
    }

    var isSupplementButtonVisible: Bool { currentStep.isSupplementButtonVisible }

    let input: OnboardingInput

    var isFromMain: Bool = false
    private(set) var containerSize: CGSize = .zero
    unowned let onboardingCoordinator: OnboardingRoutable
    private let saveUserWalletOnFinish: Bool

    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService

    init(input: OnboardingInput, saveUserWalletOnFinish: Bool, onboardingCoordinator: OnboardingRoutable) {
        self.input = input
        self.onboardingCoordinator = onboardingCoordinator
        self.saveUserWalletOnFinish = saveUserWalletOnFinish
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

    func skipCurrentStep() { }

    func fireConfetti() {
        if !confettiFired {
            shouldFireConfetti = true
            confettiFired = true
        }
    }

    func goToNextStep() {
        if isOnboardingFinished {
            DispatchQueue.main.async {
                self.onboardingDidFinish()
            }

            onOnboardingFinished(for: input.cardInput.cardId)

            if saveUserWalletOnFinish {
                saveUserWalletIfNeeded()
            }

            return
        }

        var newIndex = currentStepIndex + 1
        if newIndex >= steps.count {
            newIndex = steps.count - 1
        }

        withAnimation {
            currentStepIndex = newIndex

            setupCardsSettings(animated: true, isContainerSetup: false)

            if newIndex == (steps.count - 1) {
                fireConfetti()
            }
        }
    }

    func goToStep(_ step: Step) {
        guard let newIndex = steps.firstIndex(of: step) else {
            print("Failed to find step", step)
            return
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

    func skipSaveUserWallet() {
        didAskToSaveUserWallets()
        goToNextStep()
    }

    func saveUserWallet() {
        didAskToSaveUserWallets()

        userWalletListService.unlockWithBiometry { [weak self] result in
            switch result {
            case .failure(let error):
                if let tangemSdkError = error as? TangemSdkError,
                   case .userCancelled = tangemSdkError
                {
                    return
                }
                print("Failed to get access to biometry", error)
            case .success:
                AppSettings.shared.saveUserWallets = true
                AppSettings.shared.saveAccessCodes = true
                self?.saveUserWalletIfNeeded()
            }
            self?.goToNextStep()
        }
    }

    func didAskToSaveUserWallets() {
        AppSettings.shared.askedToSaveUserWallets = true
    }

    private func saveUserWalletIfNeeded() {
        guard
            AppSettings.shared.saveUserWallets,
            let userWallet = input.cardInput.cardModel?.userWallet,
            !userWalletListService.contains(userWallet)
        else {
            return
        }

        if userWalletListService.save(userWallet) {
            userWalletListService.selectedUserWalletId = userWallet.userWalletId
        }
    }
}

// MARK: - Navigation
extension OnboardingViewModel {
    func onboardingDidFinish() {
        onboardingCoordinator.onboardingDidFinish()
    }

    func closeOnboarding() {
        onboardingCoordinator.closeOnboarding()
    }
}
