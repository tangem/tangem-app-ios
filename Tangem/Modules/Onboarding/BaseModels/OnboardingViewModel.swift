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

class OnboardingViewModel<Step: OnboardingStep, Coordinator: OnboardingRoutable> {
    let navbarSize: CGSize = .init(width: UIScreen.main.bounds.width, height: 44)
    let resetAnimDuration: Double = 0.3

    @Published var steps: [Step] = []
    @Published var currentStepIndex: Int = 0
    @Published var isMainButtonBusy: Bool = false
    @Published var isSupplementButtonBusy: Bool = false
    @Published var shouldFireConfetti: Bool = false
    @Published var isInitialAnimPlayed = false
    @Published var mainCardSettings: AnimatedViewSettings = .zero
    @Published var supplementCardSettings: AnimatedViewSettings = .zero
    @Published var isNavBarVisible: Bool = false
    @Published var alert: AlertBinder?
    @Published var cardImage: Image?
    @Published var secondImage: Image?

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

    var title: LocalizedStringKey? {
        if !isInitialAnimPlayed, let welcomeStep = input.welcomeStep {
            return welcomeStep.title
        }

        return currentStep.title
    }

    var subtitle: LocalizedStringKey? {
        if !isInitialAnimPlayed, let welcomteStep = input.welcomeStep {
            return welcomteStep.subtitle
        }

        return currentStep.subtitle
    }

    var mainButtonSettings: TangemButtonSettings? {
        .init(
            title: mainButtonTitle,
            size: .wide,
            action: mainButtonAction,
            isBusy: isMainButtonBusy,
            isEnabled: true,
            isVisible: true,
            color: .black
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
            isBusy: isSupplementButtonBusy,
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

    lazy var userWalletStorageAgreementViewModel = UserWalletStorageAgreementViewModel(isStandalone: false, coordinator: nil)

    let input: OnboardingInput

    var isFromMain: Bool = false
    private(set) var containerSize: CGSize = .zero
    unowned let coordinator: Coordinator
    private let saveUserWalletOnFinish: Bool

    @Injected(\.userWalletListService) private var userWalletListService: UserWalletListService
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding

    init(input: OnboardingInput, coordinator: Coordinator, saveUserWalletOnFinish: Bool) {
        self.input = input
        self.coordinator = coordinator
        self.saveUserWalletOnFinish = saveUserWalletOnFinish
        isFromMain = input.isStandalone
        isNavBarVisible = input.isStandalone

        loadImage(
            supportsOnlineImage: input.cardInput.cardModel?.supportsOnlineImage ?? false,
            cardId: input.cardInput.cardModel?.cardId,
            cardPublicKey: input.cardInput.cardModel?.cardPublicKey
        )

        var config = TangemSdkConfigFactory().makeDefaultConfig()
        config.accessCodeRequestPolicy = .default
        tangemSdkProvider.setup(with: config)

        bindAnalytics()
    }

    deinit {
        let config = TangemSdkConfigFactory().makeDefaultConfig()
        tangemSdkProvider.setup(with: config)
    }

    func loadImage(supportsOnlineImage: Bool, cardId: String?, cardPublicKey: Data?) {
        guard let cardId = cardId, let cardPublicKey = cardPublicKey else {
            return
        }

        CardImageProvider(supportsOnlineImage: supportsOnlineImage)
            .loadImage(cardId: cardId, cardPublicKey: cardPublicKey)
            .map { Image(uiImage: $0) }
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
        AppSettings.shared.cardsStartedActivation.remove(cardId)
    }

    func backButtonAction() {}

    func skipCurrentStep() { }

    func fireConfetti() {
        if !confettiFired {
            shouldFireConfetti = true
            confettiFired = true
            Analytics.log(.walletCreatedSuccessfully)
        }
    }

    func goToStep(with index: Int) {
        withAnimation {
            currentStepIndex = index
            setupCardsSettings(animated: true, isContainerSetup: false)

            if index == (steps.count - 1) {
                fireConfetti()
            }
        }
    }

    func goToNextStep() {
        if isOnboardingFinished {
            let completion: (Result<Void, TangemSdkError>) -> Void = { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    print("Failed to complete onboarding", error)
                case .success:
                    DispatchQueue.main.async {
                        self.onboardingDidFinish()
                    }

                    self.onOnboardingFinished(for: self.input.cardInput.cardId)
                }
            }

            if saveUserWalletOnFinish {
                saveUserWalletIfNeeded(completion: completion)
            } else {
                completion(.success(()))
            }

            return
        }

        var newIndex = currentStepIndex + 1
        if newIndex >= steps.count {
            newIndex = steps.count - 1
        }

        goToStep(with: newIndex)
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
        logSaveUserWalletStep(agreed: false)

        didAskToSaveUserWallets()
        goToNextStep()
    }

    func saveUserWallet() {
        logSaveUserWalletStep(agreed: true)

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
                self?.goToNextStep()
            case .success:
                AppSettings.shared.saveUserWallets = true
                AppSettings.shared.saveAccessCodes = true
                self?.saveUserWalletIfNeeded { result in
                    switch result {
                    case .failure(let error):
                        print("Failed to save user wallet", error)
                    case .success:
                        self?.goToNextStep()
                    }
                }
            }
        }
    }

    func didAskToSaveUserWallets() {
        AppSettings.shared.askedToSaveUserWallets = true
    }

    func saveUserWalletIfNeeded(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard
            AppSettings.shared.saveUserWallets,
            let userWallet = input.cardInput.cardModel?.userWallet,
            !userWalletListService.contains(userWallet)
        else {
            completion(.success(()))
            return
        }

        if userWalletListService.save(userWallet) {
            userWalletListService.selectedUserWalletId = userWallet.userWalletId
        }

        completion(.success(()))
    }

    private func bindAnalytics() {
        $currentStepIndex
            .dropFirst()
            .removeDuplicates()
            .receiveValue { [weak self] index in
                guard let self else { return }

                let currentStep = self.currentStep

                if let walletStep = currentStep as? WalletOnboardingStep {
                    switch walletStep {
                    case .kycProgress:
                        Analytics.log(.kycProgressScreenOpened)
                    case .kycRetry:
                        Analytics.log(.kycRetryScreenOpened)
                    case .kycWaiting:
                        Analytics.log(.kycWaitingScreenOpened)
                    case .claim:
                        Analytics.log(.claimScreenOpened)
                    default:
                        break
                    }
                }
            }
            .store(in: &bag)
    }

    private func logSaveUserWalletStep(agreed: Bool) {
        let state: Analytics.ParameterValue = agreed ? .on : .off
        Analytics.log(.onboardingEnableBiometric, params: [.state: state.rawValue])
    }
}

// MARK: - Navigation
extension OnboardingViewModel {
    func onboardingDidFinish() {
        coordinator.onboardingDidFinish()
    }

    func closeOnboarding() {
        coordinator.closeOnboarding()
    }

    func openSupportChat() {
        guard let cardModel = input.cardInput.cardModel else { return }

        let dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel,
                                                         userWalletEmailData: cardModel.emailData)

        coordinator.openSupportChat(cardId: cardModel.cardId,
                                    dataCollector: dataCollector)
    }
}
