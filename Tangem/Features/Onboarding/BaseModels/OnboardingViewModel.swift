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
import TangemUI
import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.AlertBinder

class OnboardingViewModel<Step: OnboardingStep, Coordinator: OnboardingRoutable> {
    @Injected(\.userWalletRepository) var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    var navbarSize: CGSize { OnboardingLayoutConstants.navbarSize }
    var progressBarHeight: CGFloat { OnboardingLayoutConstants.progressBarHeight }
    var progressBarPadding: CGFloat { OnboardingLayoutConstants.progressBarPadding }
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
    @Published var mainImage: Image?
    @Published var secondImage: Image?
    @Published var thirdImage: Image?

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
            userWalletModel.config.hasFeature(.multiCurrency),
            let context = makeManageTokensContext(for: userWalletModel)
        else {
            goToNextStep()
            return nil
        }

        let analyticsSourceRawValue = Analytics.ParameterValue.onboarding.rawValue
        let analyticsParams: [Analytics.ParameterKey: String] = [.source: analyticsSourceRawValue]

        logAnalytics(event: .manageTokensScreenOpened, params: analyticsParams)

        let manageTokensAdapter = ManageTokensAdapter(
            settings: .init(
                existingCurves: userWalletModel.config.existingCurves,
                supportedBlockchains: userWalletModel.config.supportedBlockchains,
                hardwareLimitationUtil: HardwareLimitationsUtil(config: userWalletModel.config),
                analyticsSourceRawValue: analyticsSourceRawValue,
                context: context
            )
        )

        return OnboardingAddTokensViewModel(
            adapter: manageTokensAdapter,
            delegate: self
        )
    }()

    lazy var pushNotificationsViewModel: PushNotificationsPermissionRequestViewModel? = {
        guard let permissionManager = input.pushNotificationsPermissionManager else {
            return nil
        }
        return PushNotificationsPermissionRequestViewModel(permissionManager: permissionManager, delegate: self)
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

        loadMainImage(imageProvider: input.cardInput.cardImageProvider)

        incomingActionManager.becomeFirstResponder(self)
        bindAnalytics()
    }

    func initializeUserWallet(from cardInfo: CardInfo, walletCreationType: WalletOnboardingViewModel.WalletCreationType) {
        guard userWalletModel == nil else {
            return
        }

        runTask(in: self) { _ in
            let userWalletConfig = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

            if let userWalletId = UserWalletId(config: userWalletConfig) {
                let remoteIdentifierBuilder = CryptoAccountsRemoteIdentifierBuilder(userWalletId: userWalletId)
                let mapper = CryptoAccountsNetworkMapper(
                    supportedBlockchains: userWalletConfig.supportedBlockchains,
                    remoteIdentifierBuilder: remoteIdentifierBuilder.build(from:)
                )
                let walletsNetworkService = CommonWalletsNetworkService(userWalletId: userWalletId)
                let networkService = CommonCryptoAccountsNetworkService(
                    userWalletId: userWalletId,
                    mapper: mapper,
                    walletsNetworkService: walletsNetworkService
                )
                let walletCreationHelper = WalletCreationHelper(
                    userWalletId: userWalletId,
                    userWalletName: nil,
                    userWalletConfig: userWalletConfig,
                    networkService: networkService
                )

                try? await walletCreationHelper.createWallet()
            }
        }

        guard let userWallet = CommonUserWalletModelFactory().makeModel(
            walletInfo: .cardWallet(cardInfo),
            keys: .cardWallet(keys: cardInfo.card.wallets)
        ) else {
            return
        }

        AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: userWallet.userWalletId)
        var params = walletCreationType.params
        params.enrich(with: ReferralAnalyticsHelper().getReferralParams())
        logAnalytics(event: .walletCreatedSuccessfully, params: params)

        Analytics.logTopUpIfNeeded(balance: 0, for: userWallet.userWalletId, contextParams: getContextParams())

        userWalletModel = userWallet
    }

    func handleUserWalletOnFinish() {
        // resumed backup
        guard let userWalletModel else {
            DispatchQueue.main.async {
                self.onboardingDidFinish()
            }

            onOnboardingFinished(for: input.primaryCardId)
            return
        }

        if let existingModel = userWalletRepository.models[userWalletModel.userWalletId],
           existingModel.isUserWalletLocked {
            runTask(in: self) { viewModel in
                // this card was onboarded previously but the onboarding have shown again, e.g. for pushes.
                let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: userWalletModel)
                let unlockResult = await unlocker.unlock()

                if case .success(let userWalletId, let encryptionKey) = unlockResult {
                    let method = UserWalletRepositoryUnlockMethod.encryptionKey(userWalletId: userWalletId, encryptionKey: encryptionKey)
                    _ = try? await viewModel.userWalletRepository.unlock(with: method)
                }

                await runOnMain {
                    viewModel.onboardingDidFinish()
                    viewModel.onOnboardingFinished(for: viewModel.input.primaryCardId)
                }
            }
        } else {
            // add model
            let hadSingleMobileWallet = UserWalletRepositoryModeHelper.hasSingleMobileWallet

            if AppSettings.shared.saveUserWallets {
                try? userWalletRepository.add(userWalletModel: userWalletModel)
            } else {
                // replace model
                let currentUserWalletId = userWalletRepository.selectedModel?.userWalletId
                try? userWalletRepository.add(userWalletModel: userWalletModel)

                if let currentUserWalletId {
                    userWalletRepository.delete(userWalletId: currentUserWalletId)
                }
            }

            if hadSingleMobileWallet, userWalletRepository.models.count == 2 {
                logColdWalletAddedAnalytics(contextData: userWalletModel.analyticsContextData)
            }

            DispatchQueue.main.async {
                self.onboardingDidFinish()
            }

            onOnboardingFinished(for: input.primaryCardId)
        }
    }

    func loadImage(imageLoadInput: CardImageProvider.Input) async -> Image {
        let imageProvider = CardImageProvider(input: imageLoadInput)
        let imageValue = await imageProvider.loadLargeImage()
        return imageValue.image
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
            logAnalytics(.onboardingFinished)
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
            handleUserWalletOnFinish()
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
            AppLogger.error(self, error: "Failed to find step \(step)")
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
        OnboardingUtils().processSaveUserWalletRequestResult(agreed: agreed)
    }

    func logAnalytics(_ event: Analytics.Event, params: [Analytics.ParameterKey: Analytics.ParameterValue] = [:]) {
        Analytics.log(event, params: params, contextParams: getContextParams())
    }

    func logAnalytics(event: Analytics.Event, params: [Analytics.ParameterKey: String] = [:]) {
        Analytics.log(event: event, params: params, contextParams: getContextParams())
    }

    func getContextParams() -> Analytics.ContextParams {
        let contextParams: Analytics.ContextParams

        if let userWalletModel {
            contextParams = .custom(userWalletModel.analyticsContextData)
        } else if let cardInfo = input.cardInput.cardInfo {
            contextParams = .custom(cardInfo.analyticsContextData)
        } else {
            contextParams = .default
        }

        return contextParams
    }

    private func loadMainImage(imageProvider: WalletImageProviding) {
        runTask(in: self) { model in
            let imageValue = await imageProvider.loadLargeImage()

            await runOnMain {
                withAnimation {
                    model.mainImage = imageValue.image
                }
            }
        }
    }

    private func bindAnalytics() {
        $currentStepIndex
            .removeDuplicates()
            .delay(for: 0.1, scheduler: DispatchQueue.main)
            .receiveValue { [weak self] index in
                guard let self, index < steps.count else { return }

                let currentStep = steps[index]

                if let walletStep = currentStep as? WalletOnboardingStep {
                    switch walletStep {
                    case .createWallet, .createWalletSelector:
                        logAnalytics(.createWalletScreenOpened)
                    case .backupIntro:
                        logAnalytics(.backupScreenOpened)
                    case .selectBackupCards:
                        logAnalytics(.backupStarted)
                    case .seedPhraseIntro:
                        logAnalytics(.onboardingSeedIntroScreenOpened)
                    case .seedPhraseGeneration:
                        logAnalytics(.onboardingSeedGenerationScreenOpened)
                    case .seedPhraseUserValidation:
                        logAnalytics(.onboardingSeedCheckingScreenOpened)
                    case .seedPhraseImport:
                        logAnalytics(.onboardingSeedImportScreenOpened)
                    default:
                        break
                    }
                } else if let singleCardStep = currentStep as? SingleCardOnboardingStep {
                    switch singleCardStep {
                    case .createWallet:
                        logAnalytics(.createWalletScreenOpened)
                    default:
                        break
                    }
                } else if let twinStep = currentStep as? TwinsOnboardingStep {
                    switch twinStep {
                    case .first:
                        logAnalytics(.createWalletScreenOpened)
                    case .done:
                        logAnalytics(.twinSetupFinished)
                    default:
                        break
                    }
                }
            }
            .store(in: &bag)
    }

    private func makeManageTokensContext(for userWalletModel: UserWalletModel) -> ManageTokensContext? {
        if FeatureProvider.isAvailable(.accounts) {
            makeAccountsAwareContext(for: userWalletModel)
        } else {
            makeLegacyContext(for: userWalletModel)
        }
    }

    private func makeAccountsAwareContext(for userWalletModel: UserWalletModel) -> ManageTokensContext? {
        guard let mainAccount = userWalletModel.accountModelsManager.cryptoAccountModels.first(where: { $0.isMainAccount }) else {
            return nil
        }

        // Working with accounts in onboarding is equivalent of working with main account
        return AccountsAwareManageTokensContext(
            accountModelsManager: userWalletModel.accountModelsManager,
            currentAccount: mainAccount
        )
    }

    @available(iOS, deprecated: 100000.0, message: "Only used when accounts are disabled, will be removed in the future ([REDACTED_INFO])")
    private func makeLegacyContext(for userWalletModel: UserWalletModel) -> ManageTokensContext {
        LegacyManageTokensContext(
            // accounts_fixes_needed_none
            userTokensManager: userWalletModel.userTokensManager,
            walletModelsManager: userWalletModel.walletModelsManager
        )
    }
}

// MARK: - Analytics

private extension OnboardingViewModel {
    func logColdWalletAddedAnalytics(contextData: AnalyticsContextData) {
        Analytics.log(
            .settingsColdWalletAdded,
            params: [.source: Analytics.ParameterValue.onboarding],
            analyticsSystems: .all,
            contextParams: .custom(contextData)
        )
    }
}

// MARK: - Navigation

extension OnboardingViewModel {
    func onboardingDidFinish() {
        coordinator?.onboardingDidFinish(userWalletModel: userWalletModel)
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }

    func openSupportChat() {
        let walletModels = userWalletModel.map { AccountsFeatureAwareWalletModelsResolver.walletModels(for: $0) } ?? []

        let dataCollector = DetailsFeedbackDataCollector(
            data: [
                .init(
                    userWalletEmailData: input.cardInput.emailData,
                    walletModels: walletModels
                ),
            ]
        )

        let logsComposer = LogsComposer(infoProvider: dataCollector)
        coordinator?.openSupportChat(input: .init(logsComposer: logsComposer))
        logAnalytics(.chatScreenOpened)
    }

    func openSupport() {
        logAnalytics(.requestSupport, params: [.source: .onboarding])

        // Hide keyboard on set pin screen
        UIApplication.shared.endEditing()

        let walletModels = userWalletModel.map { AccountsFeatureAwareWalletModelsResolver.walletModels(for: $0) } ?? []

        let dataCollector = DetailsFeedbackDataCollector(
            data: [
                .init(
                    userWalletEmailData: input.cardInput.emailData,
                    walletModels: walletModels
                ),
            ]
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
        OnboardingUtils().requestBiometrics { [weak self] agreed in
            self?.didAskToSaveUserWallets(agreed: agreed)
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

extension OnboardingViewModel: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        goToNextStep()
    }
}

// MARK: - IncomingActionResponder

extension OnboardingViewModel: IncomingActionResponder {
    /// Intentionally ignore all incoming actions except for promo deeplinks until onboarding is complete
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        !action.isPromoDeeplink
    }
}
