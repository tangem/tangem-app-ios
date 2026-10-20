//
//  WelcomeCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import Foundation
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemMobileWalletBackup
import TangemStories
import TangemUIUtils
import struct TangemUIUtils.AlertBinder

final class WelcomeCoordinator: CoordinatorObject {
    @Injected(\.welcomeBackgroundVideoProvider)
    private var videoProvider: WelcomeBackgroundVideoProviding

    @Injected(\.welcomeStoryProvider)
    private var welcomeStoryProvider: WelcomeStoryProviding

    @Injected(\.alertPresenter)
    private var alertPresenter: AlertPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.failedScanTracker)
    private var failedScanTracker: FailedScanTrackable

    @Injected(\.safariManager)
    private var safariManager: SafariManager

    @Injected(\.welcomeAnalyticsProvider)
    private var analytics: WelcomeAnalyticsProvider

    @Injected(\.mailComposePresenter)
    private var mailPresenter: MailComposePresenter

    @Injected(\.pushNotificationsInteractor)
    private var pushNotificationsInteractor: PushNotificationsInteractor

    var dismissAction: Action<OutputOptions>
    var popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: WelcomeViewModel?
    @Published var actionSheetViewModel: WelcomeActionSheetViewModel?
    @Published private(set) var isScanningCard = false
    @Published var importOnboardingCoordinator: OnboardingCoordinator?
    @Published var legalViewModel: WelcomeLegalViewModel?
    @Published var welcomeStoryViewModel: WelcomeStoryPresentationViewModel?
    @Published var scanTroubleshootingDialog: ConfirmationDialogViewModel?
    @Published var socialWalletViewModel: MobileSocialWalletViewModel?
    @Published var tangemPayMobileOnboardingCoordinator: TangemPayMobileOnboardingCoordinator?
    @Published var tangemPayCampaignCoordinator: TangemPayCampaignCoordinator?
    @Published var createWalletSelectorCoordinator: CreateWalletSelectorCoordinator?
    @Published private var isShopPresented = false
    @Published private var isAppleLoginInProgress = false

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()
    private let socialLoginAnalytics = MobileSocialLoginAnalyticsLogger()
    private lazy var socialLoginHelper = MobileSocialLoginHelper(output: self)

    private lazy var processor = WelcomeProcessor(isIdle: isIdlePublisher)
    private var bag: Set<AnyCancellable> = []
    private var cardScanTask: Task<Void, Never>?
    private var createMobileWalletTask: Task<Void, Never>?
    private var sheetTransitionTask: Task<Void, Never>?
    private var appleLoginTask: Task<Void, Never>?
    private var shopSafariHandle: SafariHandle?

    /// `true` while nothing the user navigated to themselves is on screen. The processor gates the promo /
    /// Tangem Pay deep links on this, so they never present over such a screen. The welcome story is not one
    /// of them: it never closes by itself, and counting it here would hold a deep link forever.
    private var isIdlePublisher: AnyPublisher<Bool, Never> {
        [
            $actionSheetViewModel.map { $0 == nil }.eraseToAnyPublisher(),
            $isScanningCard.map { !$0 }.eraseToAnyPublisher(),
            $importOnboardingCoordinator.map { $0 == nil }.eraseToAnyPublisher(),
            $createWalletSelectorCoordinator.map { $0 == nil }.eraseToAnyPublisher(),
            $scanTroubleshootingDialog.map { $0 == nil }.eraseToAnyPublisher(),
            $socialWalletViewModel.map { $0 == nil }.eraseToAnyPublisher(),
            $isShopPresented.map { !$0 }.eraseToAnyPublisher(),
            $isAppleLoginInProgress.map { !$0 }.eraseToAnyPublisher(),
        ]
        .combineLatest()
        .map { $0.allSatisfy { $0 } }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        cancelPendingTasks()
        AppLogger.debug("WelcomeCoordinator deinit")
    }

    func start(with options: Options) {
        rootViewModel = WelcomeViewModel(
            coordinator: self,
            videoProvider: videoProvider
        )
        bind()
    }

    private func bind() {
        // Touching `processor` builds it and computes the real state, so the first emission is never a placeholder.
        processor.statePublisher
            .withWeakCaptureOf(self)
            .sink { coordinator, state in
                coordinator.render(state)
            }
            .store(in: &bag)

        bindStoryCover()
    }

    /// The story is not dismissed by its own buttons any more, so whatever they open runs on top of
    /// it. Playback follows that cover, which keeps the user on the same slide once it goes away.
    private func bindStoryCover() {
        Publishers.CombineLatest3(
            $isScanningCard,
            $scanTroubleshootingDialog.map { $0 != nil },
            $isShopPresented
        )
        .map { isScanning, isTroubleshooting, isShopPresented in
            isScanning || isTroubleshooting || isShopPresented
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .withWeakCaptureOf(self)
        .sink { coordinator, isCovered in
            MainActor.assumeIsolated {
                coordinator.welcomeStoryViewModel?.setCovered(isCovered)
            }
        }
        .store(in: &bag)
    }

    private func render(_ state: WelcomeProcessor.State) {
        guard state.deepLink != nil else { return }

        closeWelcomeStory()

        switch state.deepLink {
        case .tangemPay:
            showTangemPayMobileOnboarding()
        case .tangemPayCampaign(let campaignKey):
            showTangemPayCampaign(campaignKey: campaignKey)
        case .promo:
            showMobileWalletPromo()
        case .none:
            break
        }
    }

    /// Only `CreateWalletSelectorCoordinator` reads `shouldShowMobilePromoWalletSelector` and swaps in the
    /// promo variant, so the referral deep link goes through it rather than V2's create-wallet sheet.
    private func showMobileWalletPromo() {
        guard createWalletSelectorCoordinator == nil else { return }

        let dismissAction: Action<CreateWalletSelectorCoordinator.OutputOptions> = { [weak self] options in
            guard let self else { return }

            switch options {
            case .main(let userWalletModel):
                openMain(with: userWalletModel)
            case .dismiss:
                createWalletSelectorCoordinator = nil
            }
        }

        let coordinator = CreateWalletSelectorCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(showsBackButton: false))
        createWalletSelectorCoordinator = coordinator
    }

    private func showTangemPayMobileOnboarding() {
        guard tangemPayMobileOnboardingCoordinator == nil else { return }

        let dismissAction: Action<TangemPayMobileOnboardingCoordinator.OutputOptions> = { [weak self] options in
            guard let self else { return }
            switch options {
            case .main(let userWalletModel):
                openMain(with: userWalletModel)
            }
        }

        let coordinator = TangemPayMobileOnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: ())
        tangemPayMobileOnboardingCoordinator = coordinator
    }

    private func showTangemPayCampaign(campaignKey: String) {
        guard tangemPayCampaignCoordinator == nil else { return }

        // The stored key is what carries the campaign from one launch to the next, so showing it spends
        // the key — left behind, it would make `MainCoordinator` open the campaign again every launch.
        TangemPayCampaignService().clearPending()

        let dismissAction: Action<TangemPayCampaignCoordinator.OutputOptions> = { [weak self] options in
            guard let self else { return }

            switch options {
            case .close:
                tangemPayCampaignCoordinator = nil
            case .finished(let userWalletModel), .finishedWithPlanSelection(let userWalletModel):
                openMain(with: userWalletModel)
            }
        }

        let coordinator = TangemPayCampaignCoordinator(dismissAction: dismissAction)
        coordinator.start(with: .init(campaignKey: campaignKey))
        tangemPayCampaignCoordinator = coordinator
    }

    /// The child screens are deliberately left mounted here: tearing them down runs their own pop and fade,
    /// which flashes the welcome screen back in while the root is already cross-fading away from it.
    private func cancelPendingTasks() {
        cardScanTask?.cancel()
        cardScanTask = nil
        createMobileWalletTask?.cancel()
        createMobileWalletTask = nil
        sheetTransitionTask?.cancel()
        sheetTransitionTask = nil
        cancelAppleLogin()
    }

    private func cancelAppleLogin() {
        appleLoginTask?.cancel()
        appleLoginTask = nil
        isAppleLoginInProgress = false
    }
}

// MARK: - Options

extension WelcomeCoordinator {
    struct Options {}

    enum OutputOptions {
        case main(UserWalletModel)
        case onboarding(OnboardingInput)
    }
}

// MARK: - Sheet dismissal

extension WelcomeCoordinator {
    /// Swipe-down and backdrop tap are indistinguishable by design and share the `Dismissed` value.
    func handleBackgroundSheetDismiss() {
        logVisibleSheetDismissed(reason: .welcomeDismissed)
        actionSheetViewModel = nil
        cancelPendingTasks()
    }

    /// The `Sheet` param reports what was visible at dismiss time: the pushed import sheet overrides the root.
    /// Each sheet owns its own value, so it can't drift from the one its factory set.
    func logVisibleSheetDismissed(reason: Analytics.ParameterValue) {
        guard let sheet = actionSheetViewModel else { return }

        let visible = sheet.pushedImportSheet?.analyticsSheet ?? sheet.analyticsSheet
        analytics.logSheetDismissed(sheet: visible, reason: reason)
    }
}

// MARK: - WelcomeRoutable

extension WelcomeCoordinator: WelcomeRoutable {
    func openCreateWallet() {
        presentCreateWallet()
    }

    func openExistingWallet() {
        presentExistingWallet()
    }

    func openLegal(document: WelcomeLegalDocument) {
        legalViewModel = WelcomeLegalViewModel(document: document)
    }

    func openBuyTangem() {
        openShop(url: TangemShopUrlBuilder().url(utmCampaign: .welcome), entry: .welcomeButton)
    }

    func openShop(url: URL, entry: ShopEntry) {
        // The story stays up behind the shop, so its button is still tappable while the browser opens.
        guard !isShopPresented else { return }

        switch entry {
        case .welcomeButton:
            analytics.logButtonBuyTangem()
        case .stories:
            analytics.logButtonBuy()
        }
        analytics.logShopScreenOpened()
        isShopPresented = true

        shopSafariHandle = safariManager.openURL(
            url,
            configuration: .init(),
            onDismiss: { [weak self] in
                self?.handleShopDismiss()
            },
            // A redirect closes the browser from the outside and reports success instead of a dismissal.
            onSuccess: { [weak self] _ in
                self?.handleShopDismiss()
            }
        )
    }

    func openMain(with userWalletModel: UserWalletModel) {
        cancelPendingTasks()
        reportWelcomeStoryExit()
        dismiss(with: .main(userWalletModel))
    }

    func openOnboarding(with input: OnboardingInput) {
        cancelPendingTasks()
        reportWelcomeStoryExit()
        dismiss(with: .onboarding(input))
    }
}

// MARK: - Types

extension WelcomeCoordinator {
    enum ShopEntry {
        case welcomeButton
        case stories
    }
}

// MARK: - Sheet presentation

private extension WelcomeCoordinator {
    func presentCreateWallet() {
        analytics.logCreateWalletIntroScreenOpened()
        actionSheetViewModel = WelcomeCreateWalletActionFactory().make(
            callbacks: .init(
                onHardware: { [weak self] in
                    self?.analytics.logHardwareWalletButton()
                    self?.dismissSheetThenPresentWelcomeStory()
                },
                onMobile: { [weak self] in
                    self?.analytics.logMobileWalletButton()
                    self?.createMobileWalletShortcut()
                },
                onAppleSignUp: weakify(self, forFunction: WelcomeCoordinator.appleSignUp),
                onClose: { [weak self] in
                    self?.logVisibleSheetDismissed(reason: .welcomeDismissCloseButton)
                    self?.dismissSheet()
                }
            )
        )
    }

    func presentExistingWallet() {
        analytics.logIHaveWalletIntroScreenOpened()
        actionSheetViewModel = WelcomeExistingWalletActionFactory().make(
            callbacks: .init(
                onHardware: { [weak self] in
                    self?.analytics.logSignInWithCardButton()
                    self?.dismissSheetThenScanHardwareWallet()
                },
                onImport: { [weak self] in
                    self?.analytics.logImportExistingWalletButton()
                    self?.presentImportWalletIfAvailable()
                },
                onAppleSignIn: weakify(self, forFunction: WelcomeCoordinator.appleSignIn),
                onClose: { [weak self] in
                    self?.logVisibleSheetDismissed(reason: .welcomeDismissCloseButton)
                    self?.dismissSheet()
                }
            )
        )
    }

    /// The import sheet reports `Import Wallet Request` itself once cloud availability resolves.
    /// Where it never opens, the tap is reported here instead, with no backup to offer.
    func presentImportWalletIfAvailable() {
        guard mobileWalletFeatureProvider.isAvailable else {
            analytics.logImportWalletRequest(hasCloudBackup: false)
            dismissSheet { coordinator in
                coordinator.alertPresenter.present(alert: coordinator.mobileWalletFeatureProvider.makeRestrictionAlert())
            }
            return
        }

        presentImportWallet()
    }

    func presentImportWallet() {
        guard let parent = actionSheetViewModel else { return }

        let goBack: () -> Void = { [weak self, weak parent] in
            self?.logVisibleSheetDismissed(reason: .welcomeDismissBackButton)
            parent?.pushedImportSheet = nil
        }

        let openRecoveryPhrase: () -> Void = { [weak self] in
            self?.dismissSheet { coordinator in
                let input = MobileOnboardingInput(flow: .walletImport(source: .importWallet))
                coordinator.presentImportOnboarding(options: .mobileInput(input))
            }
        }

        let openICloudBackup: ([MobileWalletBackup]) -> Void = { [weak self] backups in
            self?.dismissSheet { coordinator in
                let input = MobileOnboardingInput(flow: .iCloudBackupImport(backups: backups, source: .importWallet))
                coordinator.presentImportOnboarding(options: .mobileInput(input))
            }
        }

        parent.pushedImportSheet = WelcomeImportWalletFactory().make(
            callbacks: .init(
                onRecoveryPhrase: openRecoveryPhrase,
                onICloudBackup: openICloudBackup,
                onBack: goBack,
                onClose: { [weak self] in
                    self?.logVisibleSheetDismissed(reason: .welcomeDismissCloseButton)
                    self?.dismissSheet()
                }
            )
        )
    }

    func scanHardwareWallet() {
        guard !isScanningCard, cardScanTask == nil else { return }
        isScanningCard = true

        cardScanTask = Task { @MainActor [weak self] in
            defer {
                self?.isScanningCard = false
                self?.cardScanTask = nil
            }
            await self?.performCardScan()
        }
    }

    @MainActor
    func performCardScan() async {
        let cardScanner = CardScannerFactory().makeDefaultScanner()
        let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
        let result = await userWalletCardScanner.scanCard()

        guard !Task.isCancelled else { return }

        switch result {
        case .error(let error) where error.isCancellationError:
            analytics.logScanCancelled()

        case .error(let error):
            analytics.logScanError(error)
            alertPresenter.present(alert: error.alertBinder)

        case .scanTroubleshooting:
            analytics.logScanTroubleshooting()
            presentScanTroubleshootingDialog()

        case .onboarding(let input, _):
            analytics.logCardWasScanned(contextParams: input.cardInput.getContextParams())
            openOnboarding(with: input)

        case .success(let cardInfo):
            analytics.logCardWasScanned(contextParams: .custom(cardInfo.analyticsContextData))
            await handleScanSuccess(cardInfo: cardInfo)
        }
    }

    @MainActor
    func handleScanSuccess(cardInfo: CardInfo) async {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

        do {
            guard let userWalletId = UserWalletId(config: config),
                  let encryptionKey = UserWalletEncryptionKey(config: config) else {
                throw UserWalletRepositoryError.cantUnlockWallet
            }

            let unlockMethod = UserWalletRepositoryUnlockMethod.encryptionKey(
                userWalletId: userWalletId,
                encryptionKey: encryptionKey
            )
            let userWalletModel = try await userWalletRepository.unlock(with: unlockMethod)
            guard !Task.isCancelled else { return }
            analytics.logCardSignIn(userWalletModel: userWalletModel)
            openMain(with: userWalletModel)
        } catch UserWalletRepositoryError.notFound {
            guard !Task.isCancelled else { return }
            await handleScanNotFound(cardInfo: cardInfo)
        } catch {
            alertPresenter.present(alert: error.alertBinder)
        }
    }

    @MainActor
    func handleScanNotFound(cardInfo: CardInfo) async {
        do {
            guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
                walletInfo: .cardWallet(cardInfo),
                keys: .cardWallet(keys: cardInfo.card.wallets)
            ) else {
                throw UserWalletRepositoryError.cantUnlockWallet
            }
            guard !Task.isCancelled else { return }
            try userWalletRepository.add(userWalletModel: userWalletModel)
            analytics.logCardSignIn(userWalletModel: userWalletModel)
            openMain(with: userWalletModel)
        } catch {
            alertPresenter.present(alert: error.alertBinder)
        }
    }

    func presentScanTroubleshootingDialog() {
        let tryAgainButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonTryAgain) { [weak self] in
            self?.analytics.logTroubleshootingTryAgain()
            self?.scanHardwareWallet()
        }

        let readMoreButton = ConfirmationDialogViewModel.Button(title: Localization.commonReadMore) { [weak self] in
            self?.analytics.logTroubleshootingReadMore()
            self?.safariManager.openURL(TangemBlogUrlBuilder().url(post: .scanCard))
        }

        let requestSupportButton = ConfirmationDialogViewModel.Button(title: Localization.alertButtonRequestSupport) { [weak self] in
            self?.analytics.logTroubleshootingRequestSupport()
            self?.requestSupport()
        }

        scanTroubleshootingDialog = ConfirmationDialogViewModel(
            title: Localization.alertTroubleshootingScanCardTitle,
            subtitle: Localization.alertTroubleshootingScanCardMessage,
            buttons: [
                tryAgainButton,
                readMoreButton,
                requestSupportButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func requestSupport() {
        failedScanTracker.resetCounter()
        let mailViewModel = MailViewModel(
            logsComposer: LogsComposer(infoProvider: BaseDataCollector()),
            recipient: EmailConfig.default.recipient,
            emailType: .failedToScanCard
        )
        Task { @MainActor [mailPresenter] in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func dismissSheet() {
        actionSheetViewModel = nil
        cancelAppleLogin()
    }

    /// SwiftUI cannot present a fullScreenCover or a navigation push while a sheet is up, so we close
    /// the sheet first and wait for the dismiss animation before continuing. Closing it also makes the
    /// coordinator idle, which lets a pending deep link take the screen — hence the re-check on wake.
    func dismissSheet(then action: @MainActor @escaping (WelcomeCoordinator) -> Void) {
        actionSheetViewModel = nil
        cancelAppleLogin()
        sheetTransitionTask?.cancel()

        sheetTransitionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Constants.sheetTransitionDelay))

            guard let self, !Task.isCancelled else { return }

            sheetTransitionTask = nil

            guard actionSheetViewModel == nil,
                  importOnboardingCoordinator == nil,
                  tangemPayMobileOnboardingCoordinator == nil,
                  tangemPayCampaignCoordinator == nil,
                  createWalletSelectorCoordinator == nil else {
                return
            }

            action(self)
        }
    }

    func dismissSheetThenScanHardwareWallet() {
        dismissSheet { $0.scanHardwareWallet() }
    }

    func dismissSheetThenPresentWelcomeStory() {
        dismissSheet { $0.presentWelcomeStory() }
    }

    @MainActor
    func presentWelcomeStory() {
        let vm = WelcomeStoryPresentationViewModelFactory().make(
            provider: welcomeStoryProvider,
            onAction: { [weak self] action in
                self?.handleWelcomeStoryAction(action)
            },
            onFinished: { [weak self] reason, _ in
                self?.handleWelcomeStoryFinish(reason: reason)
            }
        )

        guard let vm else {
            // Without the story the scan button is never shown, but the scan still starts here,
            // so its start event has to fire for the scan outcomes to have a denominator.
            analytics.logButtonScanCard()
            scanHardwareWallet()
            return
        }

        welcomeStoryViewModel = vm
    }

    @MainActor
    func handleWelcomeStoryAction(_ action: StoryActionV2) {
        switch action.target {
        case .screen(let key) where key == WelcomeStoryPresentationViewModelFactory.ScreenKey.hardwareWallet:
            analytics.logButtonScanCard()
            scanHardwareWallet()
        case .web(let raw):
            // Https-only, defense in depth: this action is built locally by our own factory,
            // so the host allowlist applied to remote stories is not needed here.
            guard let url = URL(string: raw), url.scheme?.lowercased() == "https" else { return }
            openShop(url: url, entry: .stories)
        case .screen, .deeplink, .close:
            break
        }
    }

    @MainActor
    func handleWelcomeStoryFinish(reason: StoryExitReason) {
        switch reason {
        case .closeButton, .swipeDown, .completed:
            welcomeStoryViewModel = nil
        case .action:
            // The scan has taken the user off welcome. Unmounting the story here would run its own
            // fade and flash welcome back in while the root is already cross-fading away from it.
            break
        }
    }

    func handleShopDismiss() {
        isShopPresented = false
        shopSafariHandle = nil
    }

    func reportWelcomeStoryExit() {
        MainActor.assumeIsolated {
            welcomeStoryViewModel?.closeAfterScan()
        }
    }

    func closeWelcomeStory() {
        MainActor.assumeIsolated {
            welcomeStoryViewModel?.cancel()
            welcomeStoryViewModel = nil
        }
    }

    func createMobileWalletShortcut() {
        guard mobileWalletFeatureProvider.isAvailable else {
            alertPresenter.present(alert: mobileWalletFeatureProvider.makeRestrictionAlert())
            return
        }

        guard createMobileWalletTask == nil else { return }

        actionSheetViewModel?.setLoading(true, for: Constants.mobileCreateRowId)

        createMobileWalletTask = Task { @MainActor [weak self] in
            defer {
                self?.actionSheetViewModel?.setLoading(false, for: Constants.mobileCreateRowId)
                self?.createMobileWalletTask = nil
            }
            guard let self else { return }
            do {
                try await performMobileWalletShortcut()
            } catch {
                guard !Task.isCancelled else { return }
                AppLogger.error("Welcome V2: failed to create mobile wallet", error: error)
                alertPresenter.present(alert: error.alertBinder)
            }
        }
    }

    @MainActor
    private func performMobileWalletShortcut() async throws {
        let userWalletModel = try await MobileCreationUtil().makeCreatedModel()

        guard !Task.isCancelled else { return }

        AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: userWalletModel.userWalletId)
        logWalletCreatedAnalytics()

        BackendAuthenticationRegistrar.registerNewUnprotectedMobileWallet(userWalletModel)
        try userWalletRepository.add(userWalletModel: userWalletModel)
        pushNotificationsInteractor.suppressAfterLoginRequestsInCurrentSession()

        guard !Task.isCancelled else { return }

        openMain(with: userWalletModel)
    }

    private func logWalletCreatedAnalytics() {
        var params: [Analytics.ParameterKey: String] = [
            .creationType: Analytics.ParameterValue.walletCreationTypeNewSeed.rawValue,
            .seedLength: Constants.seedPhraseLength,
            .passphrase: Analytics.ParameterValue.empty.rawValue,
            .source: Analytics.ParameterValue.createWalletIntro.rawValue,
        ]

        params.enrich(with: ReferralAnalyticsHelper().getReferralParams())

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
            analyticsSystems: .all,
            contextParams: .custom(.mobileWallet)
        )
    }

    func appleSignUp() {
        appleLogin(source: .createWallet)
    }

    func appleSignIn() {
        appleLogin(source: .importWallet)
    }

    private func appleLogin(source: MobileSocialLoginSource) {
        socialLoginAnalytics.logContinueWithAppleButton(source: source)

        guard mobileWalletFeatureProvider.isAvailable else {
            socialLoginAnalytics.logMinOSNotSupportedNotice()
            alertPresenter.present(alert: mobileWalletFeatureProvider.makeRestrictionAlert())
            return
        }

        guard appleLoginTask == nil else { return }

        isAppleLoginInProgress = true
        appleLoginTask = runTask(in: self) { @MainActor coordinator in
            await coordinator.socialLoginHelper.signIn()
            coordinator.appleLoginTask = nil
            coordinator.isAppleLoginInProgress = false
        }
    }

    func presentImportOnboarding(options: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] outputOptions in
            guard let self else { return }

            switch outputOptions {
            case .main(let userWalletModel):
                openMain(with: userWalletModel)
            case .dismiss:
                importOnboardingCoordinator = nil
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        importOnboardingCoordinator = coordinator
    }
}

// MARK: - MobileSocialLoginOutput

extension WelcomeCoordinator: MobileSocialLoginOutput {
    func socialLoginWillPresentSignIn() {
        actionSheetViewModel = nil
    }

    func socialLoginLoading(_ isLoading: Bool) {
        actionSheetViewModel?.setLoading(isLoading, for: Constants.appleLoginRowId)
    }

    func socialLoginProcessing(_ isProcessing: Bool) {
        rootViewModel?.set(isProcessing: isProcessing)
    }

    func socialLoginCompleted(input: MobileSocialWalletInput) {
        socialWalletViewModel = MobileSocialWalletViewModel(
            input: input,
            socialAuthProvider: MobileSocialLoginProviderFactory.makeProvider(),
            backupManager: CommonMobileWalletSocialBackupManager(destination: .iCloud),
            coordinator: self
        )
    }

    func socialLoginFailed(failure: MobileSocialWalletFailure) {
        socialLoginAnalytics.logErrorShown(message: failure.message)
        rootViewModel?.showSnackbar(withMessage: failure.message)
    }
}

// MARK: - MobileCreateSocialWalletRoutable

extension WelcomeCoordinator: MobileSocialWalletRoutable {
    func socialWalletOpenMain(userWalletModel: UserWalletModel) {
        openMain(with: userWalletModel)
    }

    func socialWalletFailed(failure: MobileSocialWalletFailure) {
        socialLoginAnalytics.logErrorShown(message: failure.message)
        rootViewModel?.showSnackbar(withMessage: failure.message)
    }

    func socialWalletClose() {
        socialWalletViewModel = nil
    }
}

// MARK: - Constants

private extension WelcomeCoordinator {
    enum Constants {
        static let sheetTransitionDelay: TimeInterval = 0.35
        static let mobileCreateRowId = "mobile"
        static let appleLoginRowId = "appleLogin"
        static let seedPhraseLength = "12"
    }
}
