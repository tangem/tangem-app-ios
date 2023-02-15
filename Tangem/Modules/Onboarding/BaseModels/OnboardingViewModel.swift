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
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding
    @Injected(\.keysManager) private var keysManager: KeysManager

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
        steps[currentStepIndex]
    }

    var currentProgress: CGFloat {
        CGFloat(currentStepIndex + 1) / CGFloat(input.steps.stepsCount)
    }

    var navbarTitle: String {
        Localization.onboardingGettingStarted
    }

    var title: String? {
        currentStep.title
    }

    var subtitle: String? {
        currentStep.subtitle
    }

    var mainButtonSettings: MainButton.Settings? {
        MainButton.Settings(
            title: mainButtonTitle,
            style: .primary,
            isLoading: isMainButtonBusy,
            action: mainButtonAction
        )
    }

    var isOnboardingFinished: Bool {
        currentStep == steps.last
    }

    var mainButtonTitle: String {
        currentStep.mainButtonTitle
    }

    var supplementButtonSettings: TangemButtonSettings? {
        .init(
            title: supplementButtonTitle,
            size: .wide,
            action: supplementButtonAction,
            isBusy: isSupplementButtonBusy,
            isEnabled: isSupplementButtonEnabled,
            isVisible: isSupplementButtonVisible,
            color: supplementButtonColor
        )
    }

    var isSupplementButtonEnabled: Bool {
        return true
    }

    var supplementButtonColor: ButtonColorStyle {
        .transparentWhite
    }

    var supplementButtonTitle: String {
        currentStep.supplementButtonTitle
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

    lazy var userWalletStorageAgreementViewModel = UserWalletStorageAgreementViewModel(coordinator: self)

    var disclaimerModel: DisclaimerViewModel? {
        guard let url = input.cardInput.cardModel?.cardDisclaimer.url else {
            return nil
        }

        return .init(url: url, style: .onboarding)
    }

    let input: OnboardingInput

    var isFromMain: Bool = false
    private(set) var containerSize: CGSize = .zero
    unowned let coordinator: Coordinator

    init(input: OnboardingInput, coordinator: Coordinator) {
        self.input = input
        self.coordinator = coordinator
        isFromMain = input.isStandalone
        isNavBarVisible = input.isStandalone

        loadImage(
            supportsOnlineImage: input.cardInput.cardModel?.supportsOnlineImage ?? false,
            cardId: input.cardInput.cardModel?.cardId,
            cardPublicKey: input.cardInput.cardModel?.cardPublicKey
        )

        bindAnalytics()
    }

    func loadImage(supportsOnlineImage: Bool, cardId: String?, cardPublicKey: Data?) {
        guard let cardId = cardId, let cardPublicKey = cardPublicKey else {
            return
        }

        CardImageProvider(supportsOnlineImage: supportsOnlineImage)
            .loadImage(cardId: cardId, cardPublicKey: cardPublicKey)
            .map { $0.image }
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
        if (isFromMain && isInitialAnimPlayed) || isInitialSetup {
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
        Analytics.log(.onboardingFinished)
    }

    func backButtonAction() {}

    func fireConfetti() {
        if !confettiFired {
            shouldFireConfetti = true
            confettiFired = true
        }
    }

    func goToStep(with index: Int) {
        withAnimation {
            currentStepIndex = index
            setupCardsSettings(animated: true, isContainerSetup: false)
        }
    }

    func goToNextStep() {
        if isOnboardingFinished {
            do {
                try handleUserWalletOnFinish()
            } catch {
                AppLog.shared.error(error)
                return
            }

            DispatchQueue.main.async {
                self.onboardingDidFinish()
            }

            onOnboardingFinished(for: input.cardInput.cardId)

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
            AppLog.shared.debug("Failed to find step \(step)")
            return
        }

        goToStep(with: newIndex)
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

    func didAskToSaveUserWallets(agreed: Bool) {
        AppSettings.shared.askedToSaveUserWallets = true

        AppSettings.shared.saveUserWallets = agreed
        AppSettings.shared.saveAccessCodes = agreed

        Analytics.log(.onboardingEnableBiometric, params: [.state: Analytics.ParameterValue.state(for: agreed)])
    }

    func handleUserWalletOnFinish() throws {
        guard
            AppSettings.shared.saveUserWallets,
            let userWallet = input.cardInput.cardModel?.userWallet
        else {
            return
        }

        userWalletRepository.save(userWallet)
        userWalletRepository.setSelectedUserWalletId(userWallet.userWalletId, reason: .inserted)
    }

    func disclaimerAccepted() {
        guard let id = input.cardInput.cardModel?.cardDisclaimer.id else {
            return
        }

        AppSettings.shared.termsOfServicesAccepted.append(id)
    }

    private func bindAnalytics() {
        $currentStepIndex
            .removeDuplicates()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .receiveValue { [weak self] index in
                guard let steps = self?.steps,
                      index < steps.count else { return }

                let currentStep = steps[index]

                if let walletStep = currentStep as? WalletOnboardingStep {
                    switch walletStep {
                    case .createWallet:
                        Analytics.log(.createWalletScreenOpened)
                    case .backupIntro:
                        Analytics.log(.backupScreenOpened)
                    case .kycStart:
                        Analytics.log(.kycStartScreenOpened)
                    case .kycProgress:
                        Analytics.log(.kycProgressScreenOpened)
                    case .kycRetry:
                        Analytics.log(.kycRetryScreenOpened)
                    case .kycWaiting:
                        Analytics.log(.kycWaitingScreenOpened)
                    case .claim:
                        Analytics.log(.claimScreenOpened)
                    case .enterPin:
                        Analytics.log(.pinScreenOpened)
                    default:
                        break
                    }
                } else if let singleCardStep = currentStep as? SingleCardOnboardingStep {
                    switch singleCardStep {
                    case .createWallet:
                        Analytics.log(.createWalletScreenOpened)
                    case .topup:
                        Analytics.log(.activationScreenOpened)
                    default:
                        break
                    }
                } else if let twinStep = currentStep as? TwinsOnboardingStep {
                    switch twinStep {
                    case .first:
                        Analytics.log(.createWalletScreenOpened)
                    case .topup:
                        Analytics.log(.twinSetupFinished)
                        Analytics.log(.activationScreenOpened)
                    default:
                        break
                    }
                }
            }
            .store(in: &bag)
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
        Analytics.log(.onboardingButtonChat)

        switch cardModel.supportChatEnvironment {
        case .tangem:
            let dataCollector = DetailsFeedbackDataCollector(
                cardModel: cardModel,
                userWalletEmailData: cardModel.emailData
            )

            coordinator.openSupportChat(
                cardId: cardModel.cardId,
                dataCollector: dataCollector
            )
        case .saltPay:
            coordinator.openSprinklSupportChat(appID: keysManager.saltPay.sprinklrAppID)
        }
    }
}

extension OnboardingViewModel: UserWalletStorageAgreementRoutable {
    func didAgreeToSaveUserWallets() {
        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            let biometryAccessGranted: Bool
            switch result {
            case .error(let error):
                if let tangemSdkError = error as? TangemSdkError,
                   case .userCancelled = tangemSdkError {
                    return
                }
                AppLog.shared.error(error)

                biometryAccessGranted = false
                self?.didAskToSaveUserWallets(agreed: false)
            default:
                biometryAccessGranted = true
                self?.didAskToSaveUserWallets(agreed: true)
            }

            Analytics.log(.allowBiometricID, params: [
                .state: Analytics.ParameterValue.state(for: biometryAccessGranted),
            ])

            self?.goToNextStep()
        }
    }

    func didDeclineToSaveUserWallets() {
        didAskToSaveUserWallets(agreed: false)
        goToNextStep()
    }
}
