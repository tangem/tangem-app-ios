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
    @Published var customOnboardingImage: Image?
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
            icon: mainButtonIcon,
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

    var mainButtonIcon: MainButton.Icon? {
        if let icon = currentStep.mainButtonIcon {
            return .trailing(icon)
        }

        return nil
    }

    var supplementButtonSettings: MainButton.Settings? {
        .init(
            title: supplementButtonTitle,
            icon: supplementButtonIcon,
            style: supplementButtonStyle,
            size: .default,
            isLoading: isSupplementButtonBusy,
            isDisabled: !isSupplementButtonEnabled,
            action: { [weak self] in
                self?.supplementButtonAction()
            }
        )
    }

    var supplementButtonIcon: MainButton.Icon? {
        if let icon = currentStep.supplementButtonIcon {
            return .trailing(icon)
        }

        return nil
    }

    var isSupplementButtonEnabled: Bool {
        return true
    }

    var supplementButtonStyle: MainButton.Style {
        return .secondary
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

    var isSupportButtonVisible: Bool {
        return true
    }

    var isBackButtonEnabled: Bool {
        true
    }

    lazy var userWalletStorageAgreementViewModel = UserWalletStorageAgreementViewModel(coordinator: self)
    lazy var addTokensViewModel: OnboardingAddTokensViewModel? = {
        guard
            let userWalletModel,
            userWalletModel.config.hasFeature(.multiCurrency)
        else {
            goToNextStep()
            return nil
        }

        let manageTokensAdapter = ManageTokensAdapter(settings: .init(
            longHashesSupported: userWalletModel.config.hasFeature(.longHashes),
            existingCurves: userWalletModel.config.existingCurves,
            supportedBlockchains: userWalletModel.config.supportedBlockchains,
            userTokensManager: userWalletModel.userTokensManager
        ))

        return OnboardingAddTokensViewModel(
            adapter: manageTokensAdapter,
            delegate: self
        )
    }()

    let input: OnboardingInput

    var isFromMain: Bool = false
    private(set) var containerSize: CGSize = .zero
    weak var coordinator: Coordinator?

    var userWalletModel: UserWalletModel?

    init(input: OnboardingInput, coordinator: Coordinator) {
        self.input = input
        self.coordinator = coordinator

        if let userWalletModel = input.cardInput.userWalletModel {
            self.userWalletModel = userWalletModel
        }

        isFromMain = input.isStandalone
        isNavBarVisible = input.isStandalone

        let loadImageInput = input.cardInput.imageLoadInput
        loadImage(
            supportsOnlineImage: loadImageInput.supportsOnlineImage,
            cardId: loadImageInput.cardId,
            cardPublicKey: loadImageInput.cardPublicKey
        )

        bindAnalytics()
    }

    func initializeUserWallet(from cardInfo: CardInfo) {
        guard let userWallet = CommonUserWalletModel(cardInfo: cardInfo) else { return }

        userWalletRepository.initializeServices(for: userWallet)

        Analytics.logTopUpIfNeeded(balance: 0, for: userWallet.userWalletId)

        userWalletModel = userWallet
    }

    func handleUserWalletOnFinish() throws {
        guard let userWalletModel else {
            return
        }

        userWalletRepository.add(userWalletModel)
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
        if AppSettings.shared.cardsStartedActivation.contains(cardId) {
            Analytics.log(.onboardingFinished)
            AppSettings.shared.cardsStartedActivation.remove(cardId)
        }
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

            onOnboardingFinished(for: input.primaryCardId)

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

        Analytics.log(.onboardingEnableBiometric, params: [.state: Analytics.ParameterValue.toggleState(for: agreed)])
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
                    case .createWallet, .createWalletSelector:
                        Analytics.log(.createWalletScreenOpened)
                    case .backupIntro:
                        Analytics.log(.backupScreenOpened)
                    case .selectBackupCards:
                        Analytics.log(.backupStarted)
                    case .seedPhraseIntro:
                        Analytics.log(.onboardingSeedIntroScreenOpened)
                    case .seedPhraseGeneration:
                        Analytics.log(.onboardingSeedGenerationScreenOpened)
                    case .seedPhraseUserValidation:
                        Analytics.log(.onboardingSeedCheckingScreenOpened)
                    case .seedPhraseImport:
                        Analytics.log(.onboardingSeedImportScreenOpened)
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
        coordinator?.onboardingDidFinish(userWalletModel: userWalletModel)
    }

    func closeOnboarding() {
        // reset services before exit
        userWalletRepository.updateSelection()
        coordinator?.closeOnboarding()
    }

    func openSupport() {
        Analytics.log(.requestSupport, params: [.source: .onboarding])

        // Hide keyboard on set pin screen
        UIApplication.shared.endEditing()

        let dataCollector = DetailsFeedbackDataCollector(
            walletModels: userWalletModel?.walletModelsManager.walletModels ?? [],
            userWalletEmailData: input.cardInput.emailData
        )

        let emailConfig = input.cardInput.config?.emailConfig ?? .default

        coordinator?.openMail(
            with: dataCollector,
            recipient: emailConfig.recipient,
            emailType: .appFeedback(subject: emailConfig.subject)
        )
    }
}

extension OnboardingViewModel: UserWalletStorageAgreementRoutable {
    func didAgreeToSaveUserWallets() {
        BiometricsUtil.requestAccess(localizedReason: Localization.biometryTouchIdReason) { [weak self] result in
            let biometryAccessGranted: Bool
            switch result {
            case .failure(let error):
                if error.isUserCancelled {
                    return
                }

                AppLog.shared.error(error)

                biometryAccessGranted = false
                self?.didAskToSaveUserWallets(agreed: false)
            case .success:
                biometryAccessGranted = true
                self?.didAskToSaveUserWallets(agreed: true)
            }

            Analytics.log(.allowBiometricID, params: [
                .state: Analytics.ParameterValue.toggleState(for: biometryAccessGranted),
            ])

            self?.goToNextStep()
        }
    }

    func didDeclineToSaveUserWallets() {
        didAskToSaveUserWallets(agreed: false)
        goToNextStep()
    }
}

extension OnboardingViewModel: OnboardingAddTokensDelegate {
    func showAlert(_ alert: AlertBinder) {
        self.alert = alert
    }
}
