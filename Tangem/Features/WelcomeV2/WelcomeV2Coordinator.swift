//
//  WelcomeV2Coordinator.swift
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
import struct TangemUIUtils.AlertBinder

final class WelcomeV2Coordinator: CoordinatorObject {
    @Injected(\.welcomeV2BackgroundVideoProvider)
    private var videoProvider: WelcomeV2BackgroundVideoProviding

    @Injected(\.welcomeStoryProvider)
    private var welcomeStoryProvider: WelcomeStoryProviding

    @Injected(\.alertPresenter)
    private var alertPresenter: AlertPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.safariManager)
    private var safariManager: SafariManager

    var dismissAction: Action<OutputOptions>
    var popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: WelcomeV2ViewModel?
    @Published var actionSheetViewModel: WelcomeV2ActionSheetViewModel?
    @Published private(set) var isScanningCard = false
    @Published var mobileCreateWalletCoordinator: MobileCreateWalletCoordinator?
    @Published var importOnboardingCoordinator: OnboardingCoordinator?
    @Published var legalWebViewModel: WebViewContainerViewModel?
    @Published var welcomeStoryViewModel: WelcomeStoryPresentationViewModel?
    @Published var tangemPayMobileOnboardingCoordinator: TangemPayMobileOnboardingCoordinator?

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()

    private lazy var processor = WelcomeProcessor(isIdle: isIdlePublisher)
    private var bag: Set<AnyCancellable> = []
    private var cardScanTask: Task<Void, Never>?

    /// `true` while nothing the user navigated to themselves is on screen. The processor gates the promo /
    /// Tangem Pay deep links on this, so they never present over such a screen.
    private var isIdlePublisher: AnyPublisher<Bool, Never> {
        [
            $actionSheetViewModel.map { $0 == nil }.eraseToAnyPublisher(),
            $isScanningCard.map { !$0 }.eraseToAnyPublisher(),
            $mobileCreateWalletCoordinator.map { $0 == nil }.eraseToAnyPublisher(),
            $importOnboardingCoordinator.map { $0 == nil }.eraseToAnyPublisher(),
            $welcomeStoryViewModel.map { $0 == nil }.eraseToAnyPublisher(),
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
        cardScanTask?.cancel()
        AppLogger.debug("WelcomeV2Coordinator deinit")
    }

    func start(with options: Options) {
        rootViewModel = WelcomeV2ViewModel(
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
    }

    /// V2 renders only the processor's deep links; the legacy welcome-onboarding steps (TOS + push soft-ask)
    /// are intentionally skipped — V2's design doesn't replicate the old modal onboarding on top of welcome.
    private func render(_ state: WelcomeProcessor.State) {
        switch state.deepLink {
        case .tangemPay:
            showTangemPayMobileOnboarding()
        case .promo:
            presentCreateWallet()
        case .none:
            break
        }
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

    private func resetChildCoordinators() {
        cardScanTask?.cancel()
        cardScanTask = nil
        mobileCreateWalletCoordinator = nil
        importOnboardingCoordinator = nil
        tangemPayMobileOnboardingCoordinator = nil
        welcomeStoryViewModel = nil
    }
}

// MARK: - Options

extension WelcomeV2Coordinator {
    struct Options {}

    typealias OutputOptions = WelcomeCoordinator.OutputOptions
}

// MARK: - WelcomeV2Routable

extension WelcomeV2Coordinator: WelcomeV2Routable {
    func openCreateWallet() {
        presentCreateWallet()
    }

    func openExistingWallet() {
        presentExistingWallet()
    }

    func openLegal(url: URL) {
        legalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: "",
            withCloseButton: true,
            withNavigationBar: false
        )
    }

    func openShop(url: URL) {
        safariManager.openURL(url)
    }

    func openMain(with userWalletModel: UserWalletModel) {
        resetChildCoordinators()
        dismiss(with: .main(userWalletModel))
    }

    func openOnboarding(with input: OnboardingInput) {
        resetChildCoordinators()
        dismiss(with: .onboarding(input))
    }
}

// MARK: - Sheet presentation

private extension WelcomeV2Coordinator {
    func presentCreateWallet() {
        actionSheetViewModel = WelcomeV2CreateWalletActionFactory().make(
            callbacks: .init(
                onHardware: weakify(self, forFunction: WelcomeV2Coordinator.dismissSheetThenPresentWelcomeStory),
                onMobile: weakify(self, forFunction: WelcomeV2Coordinator.dismissSheetThenPresentMobile),
                onClose: weakify(self, forFunction: WelcomeV2Coordinator.dismissSheet)
            )
        )
    }

    func presentExistingWallet() {
        actionSheetViewModel = WelcomeV2ExistingWalletActionFactory().make(
            callbacks: .init(
                onHardware: weakify(self, forFunction: WelcomeV2Coordinator.dismissSheetThenScanHardwareWallet),
                onImport: weakify(self, forFunction: WelcomeV2Coordinator.presentImportWalletIfAvailable),
                onClose: weakify(self, forFunction: WelcomeV2Coordinator.dismissSheet)
            )
        )
    }

    func presentImportWalletIfAvailable() {
        guard mobileWalletFeatureProvider.isAvailable else {
            actionSheetViewModel = nil
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Constants.sheetTransitionDelay))
                guard let self else { return }
                alertPresenter.present(alert: mobileWalletFeatureProvider.makeRestrictionAlert())
            }
            return
        }

        guard FeatureProvider.isAvailable(.mobileWalletBackup) else {
            actionSheetViewModel = nil
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Constants.sheetTransitionDelay))
                let input = MobileOnboardingInput(flow: .walletImport(source: .importWallet))
                self?.presentImportOnboarding(options: .mobileInput(input))
            }
            return
        }

        presentImportWallet()
    }

    func presentImportWallet() {
        guard let parent = actionSheetViewModel else { return }

        let goBack: () -> Void = { [weak parent] in
            parent?.pushedImportSheet = nil
        }

        let openRecoveryPhrase: () -> Void = { [weak self] in
            self?.actionSheetViewModel = nil
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Constants.sheetTransitionDelay))
                let input = MobileOnboardingInput(flow: .walletImport(source: .importWallet))
                self?.presentImportOnboarding(options: .mobileInput(input))
            }
        }

        let openICloudBackup: ([MobileWalletBackup]) -> Void = { [weak self] backups in
            self?.actionSheetViewModel = nil
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Constants.sheetTransitionDelay))
                let input = MobileOnboardingInput(flow: .iCloudBackupImport(backups: backups, source: .importWallet))
                self?.presentImportOnboarding(options: .mobileInput(input))
            }
        }

        parent.pushedImportSheet = WelcomeV2ImportWalletFactory().make(
            callbacks: .init(
                onRecoveryPhrase: openRecoveryPhrase,
                onICloudBackup: openICloudBackup,
                onBack: goBack,
                onClose: weakify(self, forFunction: WelcomeV2Coordinator.dismissSheet)
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
            break

        case .error(let error):
            alertPresenter.present(alert: error.alertBinder)

        case .scanTroubleshooting:
            alertPresenter.present(alert: AlertBinder(
                title: Localization.alertTroubleshootingScanCardTitle,
                message: Localization.alertTroubleshootingScanCardMessage
            ))

        case .onboarding(let input, _):
            openOnboarding(with: input)

        case .success(let cardInfo):
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
            openMain(with: userWalletModel)
        } catch {
            alertPresenter.present(alert: error.alertBinder)
        }
    }

    func dismissSheet() {
        actionSheetViewModel = nil
    }

    /// SwiftUI cannot present a fullScreenCover or a navigation push while a sheet is up,
    /// so we close the sheet first and wait for the dismiss animation before continuing.
    func dismissSheetThenScanHardwareWallet() {
        actionSheetViewModel = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Constants.sheetTransitionDelay))
            self?.scanHardwareWallet()
        }
    }

    func dismissSheetThenPresentMobile() {
        actionSheetViewModel = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Constants.sheetTransitionDelay))
            self?.presentCreateMobileWallet()
        }
    }

    func dismissSheetThenPresentWelcomeStory() {
        actionSheetViewModel = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Constants.sheetTransitionDelay))
            self?.presentWelcomeStory()
        }
    }

    @MainActor
    func presentWelcomeStory() {
        let vm = WelcomeStoryPresentationViewModelFactory().make(
            provider: welcomeStoryProvider,
            onFinished: { [weak self] _, action in
                self?.handleWelcomeStoryFinish(action: action)
            }
        )

        guard let vm else {
            scanHardwareWallet()
            return
        }

        welcomeStoryViewModel = vm
    }

    @MainActor
    func handleWelcomeStoryFinish(action: StoryActionV2?) {
        welcomeStoryViewModel = nil

        switch action?.target {
        case .screen(let key) where key == WelcomeStoryPresentationViewModelFactory.ScreenKey.hardwareWallet:
            scanHardwareWallet()
        case .web(let raw):
            // Https-only, defense in depth: this action is built locally by our own factory,
            // so the host allowlist applied to remote stories is not needed here.
            guard let url = URL(string: raw), url.scheme?.lowercased() == "https" else { return }
            openShop(url: url)
        case .screen, .deeplink, .close, nil:
            break
        }
    }

    func presentCreateMobileWallet() {
        guard mobileWalletFeatureProvider.isAvailable else {
            alertPresenter.present(alert: mobileWalletFeatureProvider.makeRestrictionAlert())
            return
        }

        let dismissAction: Action<MobileCreateWalletCoordinator.OutputOptions> = { [weak self] options in
            guard let self else { return }

            switch options {
            case .main(let userWalletModel):
                mobileCreateWalletCoordinator = nil
                dismiss(with: .main(userWalletModel))
            case .dismiss:
                mobileCreateWalletCoordinator = nil
            }
        }

        let coordinator = MobileCreateWalletCoordinator(dismissAction: dismissAction)
        coordinator.start(with: MobileCreateWalletCoordinator.InputOptions(source: .createWalletIntro))
        mobileCreateWalletCoordinator = coordinator
    }

    func presentImportOnboarding(options: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] outputOptions in
            guard let self else { return }

            switch outputOptions {
            case .main(let userWalletModel):
                importOnboardingCoordinator = nil
                dismiss(with: .main(userWalletModel))
            case .dismiss:
                importOnboardingCoordinator = nil
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: options)
        importOnboardingCoordinator = coordinator
    }
}

// MARK: - Constants

private extension WelcomeV2Coordinator {
    enum Constants {
        static let sheetTransitionDelay: TimeInterval = 0.35
    }
}
