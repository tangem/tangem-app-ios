//
//  AppCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CombineExt
import SwiftUI
import TangemFoundation

class AppCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    let dismissAction: Action<Void> = { _ in }

    lazy var popToRootAction: Action<PopToRootOptions> = { [weak self] _ in
        guard let self else { return }

        mainBottomSheetUIManager.hide()

        let startupProcessor = StartupProcessor()
        if startupProcessor.shouldOpenAuthScreen {
            setupAuth(unlockOnAppear: false)
        } else {
            setupWelcome()
        }
    }

    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.appLockController) private var appLockController: AppLockController
    @Injected(\.welcomeEntryReasonProvider) private var welcomeEntryReasonProvider: WelcomeEntryReasonProviding
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.servicesManager) private var servicesManager: ServicesManager
    @Injected(\.mailComposePresenter) private var mailComposePresenter: MailComposePresenter

    private let deeplinkResponders = AppSessionDeeplinkResponders()

    // MARK: - View State

    @Published private(set) var viewState: ViewState?

    // MARK: - Private

    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
        deeplinkResponders.start()
    }

    deinit {
        AppLogger.debug("AppCoordinator deinit")
    }

    func start(with options: AppCoordinator.Options = .default) {
        welcomeEntryReasonProvider.startObserving()

        let startupProcessor = StartupProcessor()
        let startupOption = startupProcessor.getStartupOption()

        switch startupOption {
        case .auth where options == .locked:
            setupLock()

            runTask(in: self) { coordinator in
                await coordinator.tryUnlockWithBiometry()
            }
        case .welcome:
            setupWelcome()
        case .auth:
            setupAuth(unlockOnAppear: true)
        case .uncompletedBackup:
            setupUncompletedBackup()
        case .main(let model):
            openMain(with: model)
        case .launchScreen:
            setupLaunch()

            runTask(in: self) { @MainActor coordinator in
                await coordinator.servicesManager.initializeKeychainSensitiveServices()
                coordinator.start(with: options)
            }
        case .jailbreakWarning:
            setupJailbreakWarning()
        case .forceUpdate(let reason):
            setupForceUpdate(reason: reason)
        }
    }

    private func tryUnlockWithBiometry() async {
        let result = await appLockController.unlockApp()

        await runOnMain {
            switch result {
            case .openAuth:
                setupAuth(unlockOnAppear: false)
            case .openMain(let model):
                openMain(with: model)
            }
        }
    }

    private func setupLock() {
        setState(.lock)
    }

    private func setupLaunch() {
        setState(.launch)
    }

    private func setupJailbreakWarning() {
        let viewModel = JailbreakWarningViewModel(coordinator: self)
        setState(.jailbreakWarning(viewModel))
    }

    private func setupForceUpdate(reason: ForceUpdateReason) {
        let viewModel = ForceUpdateViewModel(reason: reason, coordinator: self)
        setState(.forceUpdate(viewModel))
    }

    private func setupWelcome() {
        let dismissAction: Action<WelcomeCoordinator.OutputOptions> = { [weak self] options in
            guard let self else { return }

            TangemPayCampaignService().clearPending()

            switch options {
            case .main(let model):
                openMain(with: model)
            case .onboarding(let input):
                openOnboarding(with: .input(input))
            }
        }

        let welcomeCoordinator = WelcomeCoordinator(dismissAction: dismissAction)
        welcomeCoordinator.start(with: .init())
        setState(.welcome(welcomeCoordinator))
    }

    private func setupAuth(unlockOnAppear: Bool) {
        let dismissAction: Action<ScanDismissOptions> = { [weak self] options in
            guard let self else { return }

            switch options {
            case .main(let model):
                openMain(with: model)
            case .onboarding(let input):
                openOnboarding(with: .input(input))
            }
        }

        let authCoordinator = AuthCoordinator(dismissAction: dismissAction)
        authCoordinator.start(with: .init(unlockOnAppear: unlockOnAppear))

        setState(.auth(authCoordinator))
    }

    private func setupUncompletedBackup() {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.start()
        }

        let uncompleteBackupCoordinator = UncompletedBackupCoordinator(dismissAction: dismissAction)
        uncompleteBackupCoordinator.start()

        setState(.uncompleteBackup(uncompleteBackupCoordinator))
    }

    private func bind() {
        let cardSessionDidStartPublisher = NotificationCenter.default
            .publisher(for: .cardSessionDidStart)
            .map { _ in true }

        let cardSessionDidFinishPublisher = NotificationCenter.default
            .publisher(for: .cardSessionDidFinish)
            .map { _ in false }

        let cardSessionIsActivePublisher = Publishers.Merge(cardSessionDidStartPublisher, cardSessionDidFinishPublisher)
            .removeDuplicates()
            .prepend(false)

        let mobileUnlockDidStartPublisher = NotificationCenter.default
            .publisher(for: .mobileUnlockDidStart)
            .map { _ in true }

        let mobileUnlockDidFinishPublisher = NotificationCenter.default
            .publisher(for: .mobileUnlockDidFinish)
            .map { _ in false }

        let mobileUnlockIsActivePublisher = Publishers.Merge(mobileUnlockDidStartPublisher, mobileUnlockDidFinishPublisher)
            .removeDuplicates()
            .prepend(false)

        $viewState
            .dropFirst()
            .combineLatest(
                userWalletRepository.eventProvider,
                cardSessionIsActivePublisher
            )
            .combineLatest(mobileUnlockIsActivePublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] params in
                let ((viewState, walletRepositoryEvent, cardSessionIsActive), mobileUnlockIsActive) = params
                MainActor.assumeIsolated {
                    self?.updateFloatingSheetPresenterState(
                        viewState: viewState,
                        userWalletRepositoryEvent: walletRepositoryEvent,
                        cardSessionIsActive: cardSessionIsActive,
                        mobileUnlockIsActive: mobileUnlockIsActive
                    )
                }
            }
            .store(in: &bag)
    }

    private func setState(_ newViewState: AppCoordinator.ViewState) {
        DispatchQueue.main.async {
            self.viewState = newViewState
            self.updateDeeplinkSession(for: newViewState)
        }
    }

    /// The wallet session lasts exactly as long as the main screen is the app's state.
    private func updateDeeplinkSession(for viewState: ViewState) {
        guard case .main(let coordinator) = viewState else {
            deeplinkResponders.endSession()
            return
        }

        deeplinkResponders.beginSession()

        // Taken the moment the door closes, so nothing can arrive in between and be kept by nobody.
        if let action = deeplinkResponders.takeWaitingAction() {
            AppLogger.info("Waiting incoming action handed to the main screen: \(action)")
            coordinator.showWhenAppeared(action)
        }
    }

    @MainActor
    private func updateFloatingSheetPresenterState(
        viewState: ViewState?,
        userWalletRepositoryEvent: UserWalletRepositoryEvent,
        cardSessionIsActive: Bool,
        mobileUnlockIsActive: Bool
    ) {
        guard !cardSessionIsActive, !mobileUnlockIsActive else {
            floatingSheetPresenter.pauseSheetsDisplaying()
            return
        }

        guard case .main = viewState else {
            floatingSheetPresenter.pauseSheetsDisplaying()
            return
        }

        switch userWalletRepositoryEvent {
        case .locked:
            floatingSheetPresenter.removeAllSheets()
            floatingSheetPresenter.pauseSheetsDisplaying()

        case .unlocked, .inserted, .unlockedWallet, .deleted, .selected, .reordered:
            floatingSheetPresenter.resumeSheetsDisplaying()
        }
    }
}

// MARK: - Options

extension AppCoordinator {
    enum Options {
        case `default`
        case locked
    }
}

// MARK: - ViewState

extension AppCoordinator {
    enum ViewState: Equatable {
        case welcome(WelcomeCoordinator)
        case uncompleteBackup(UncompletedBackupCoordinator)
        case auth(AuthCoordinator)
        case main(MainCoordinator)
        case onboarding(OnboardingCoordinator)
        case lock
        case launch
        case jailbreakWarning(JailbreakWarningViewModel)
        case forceUpdate(ForceUpdateViewModel)

        var shouldAddLockView: Bool {
            switch self {
            case .auth, .welcome, .launch, .jailbreakWarning, .forceUpdate:
                return false
            case .lock, .main, .onboarding, .uncompleteBackup:
                return true
            }
        }

        static func == (lhs: AppCoordinator.ViewState, rhs: AppCoordinator.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.welcome, .welcome),
                 (.uncompleteBackup, .uncompleteBackup),
                 (.auth, .auth),
                 (.main, .main),
                 (.onboarding, .onboarding),
                 (.lock, .lock),
                 (.launch, .launch),
                 (.jailbreakWarning, .jailbreakWarning),
                 (.forceUpdate, .forceUpdate):
                return true
            default:
                return false
            }
        }
    }
}

// Navigation

extension AppCoordinator {
    func openOnboarding(with inputOptions: OnboardingCoordinator.Options) {
        let dismissAction: Action<OnboardingCoordinator.OutputOptions> = { [weak self] options in
            switch options {
            case .main(let userWalletModel):
                self?.openMain(with: userWalletModel)
            case .dismiss:
                self?.start()
            }
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction)
        coordinator.start(with: inputOptions)
        setState(.onboarding(coordinator))
    }

    func openMain(with userWalletModel: UserWalletModel) {
        let coordinator = MainCoordinator(
            coordinatorFactory: CommonMainCoordinatorChildFactory(),
            dismissAction: { _ in },
            popToRootAction: popToRootAction
        )

        let options = MainCoordinator.Options(userWalletModel: userWalletModel)
        coordinator.start(with: options)

        setState(.main(coordinator))
    }
}

extension AppCoordinator: JailbreakWarningRoutable {
    func closeJailbreakWarning() {
        start()
    }
}

extension AppCoordinator: ForceUpdateRoutable {
    func closeForceUpdate() {
        start()
    }

    func openSupport() {
        let logsComposer = LogsComposer(infoProvider: BaseDataCollector())
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.default.recipient,
            emailType: .appFeedback(subject: EmailConfig.default.subject)
        )

        runTask(in: self) { @MainActor coordinator in
            coordinator.mailComposePresenter.present(viewModel: mailViewModel)
        }
    }
}

// MARK: - ScanDismissOptions

enum ScanDismissOptions {
    case main(UserWalletModel)
    case onboarding(OnboardingInput)
}
