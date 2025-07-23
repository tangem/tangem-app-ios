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

        marketsCoordinator = nil
        mainBottomSheetUIManager.hide(shouldUpdateFooterSnapshot: false)

        let startupProcessor = StartupProcessor()
        if startupProcessor.shouldOpenBiometry {
            setupAuth(unlockOnAppear: false)
        } else {
            setupWelcome()
        }
    }

    // MARK: - Injected

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
    @Injected(\.appLockController) private var appLockController: AppLockController
    @Injected(\.overlayContentContainer) private var overlayContentContainer: OverlayContentContainer
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Child coordinators

    /// Published property, used by UI. `SwiftUI.Binding` API requires it to be writable,
    /// but in fact this is a read-only binding since the UI never mutates it.
    @Published var marketsCoordinator: MarketsCoordinator?

    /// An ugly workaround due to navigation issues in SwiftUI on iOS 18 and above, see [REDACTED_INFO] for details.
    @Published private(set) var isOverlayContentContainerShown = false

    // MARK: - View State

    @Published private(set) var viewState: ViewState?

    // MARK: - Private

    private var bag: Set<AnyCancellable> = []

    init() {
        bind()
    }

    deinit {
        AppLogger.debug("AppCoordinator deinit")
    }

    func start(with options: AppCoordinator.Options = .default) {
        let startupProcessor = StartupProcessor()
        let startupOption = startupProcessor.getStartupOption()

        switch startupOption {
        case .welcome where options == .locked,
             .auth where options == .locked:
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
            case .openWelcome:
                setupWelcome()
            }
        }
    }

    private func setupLock() {
        setState(.lock)
    }

    private func setupWelcome() {
        let dismissAction: Action<WelcomeCoordinator.OutputOptions> = { [weak self] options in
            guard let self else { return }

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

    /// - Note: The coordinator is set up only once and only when the feature toggle is enabled.
    private func setupMainBottomSheetCoordinatorIfNeeded() {
        guard marketsCoordinator == nil else {
            return
        }

        let dismissAction: Action<Void> = { [weak self] _ in
            self?.marketsCoordinator = nil
        }

        let coordinator = MarketsCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init())
        marketsCoordinator = coordinator
    }

    private func bind() {
        mainBottomSheetUIManager
            .isShownPublisher
            .filter { $0 }
            .withWeakCaptureOf(self)
            .sink { coordinator, _ in
                coordinator.setupMainBottomSheetCoordinatorIfNeeded()
            }
            .store(in: &bag)

        mainBottomSheetUIManager
            .isShownPublisher
            .assign(to: \.isOverlayContentContainerShown, on: self, ownership: .weak)
            .store(in: &bag)

        $isOverlayContentContainerShown
            .withWeakCaptureOf(self)
            .sink { coordinator, isShown in
                coordinator.overlayContentContainer.setOverlayHidden(!isShown)
            }
            .store(in: &bag)

        let applicationIsActivePublisher = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .map { _ in true }

        let applicationIsInactivePublisher = NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification)
            .map { _ in false }

        let applicationLifecyclePublisher = Publishers.Merge(applicationIsActivePublisher, applicationIsInactivePublisher)
            .removeDuplicates()
            .prepend(true)

        $viewState
            .dropFirst()
            .combineLatest(
                userWalletRepository.eventProvider,
                AppSettings.shared.$marketsTooltipWasShown,
                applicationLifecyclePublisher
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewState, walletRepositoryEvent, marketsTooltipWasShown, appIsActive in
                MainActor.assumeIsolated {
                    self?.updateFloatingSheetPresenterState(
                        viewState: viewState,
                        userWalletRepositoryEvent: walletRepositoryEvent,
                        marketsTooltipWasShown: marketsTooltipWasShown,
                        appIsActive: appIsActive
                    )
                }
            }
            .store(in: &bag)
    }

    private func setState(_ newViewState: AppCoordinator.ViewState) {
        DispatchQueue.main.async {
            self.viewState = newViewState
        }
    }

    @MainActor
    private func updateFloatingSheetPresenterState(
        viewState: ViewState?,
        userWalletRepositoryEvent: UserWalletRepositoryEvent,
        marketsTooltipWasShown: Bool,
        appIsActive: Bool
    ) {
        guard appIsActive, marketsTooltipWasShown else {
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

        case .unlockedBiometrics, .inserted, .unlocked, .deleted, .selected:
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

        var shouldAddLockView: Bool {
            switch self {
            case .auth, .welcome:
                return false
            case .lock, .main, .onboarding, .uncompleteBackup:
                return true
            }
        }

        static func == (lhs: AppCoordinator.ViewState, rhs: AppCoordinator.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.welcome, .welcome), (.uncompleteBackup, .uncompleteBackup), (.auth, .auth), (.main, .main):
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
        let coordinatorFactory = CommonMainCoordinatorChildFactory()
        let navigationActionHandler = MainCoordinator.MainNavigationActionHandler()
        let deeplinkPresenter = CommonDeeplinkPresenter(coordinatorFactory: coordinatorFactory)

        let coordinator = MainCoordinator(
            coordinatorFactory: coordinatorFactory,
            navigationActionHandler: navigationActionHandler,
            deeplinkPresenter: deeplinkPresenter,
            dismissAction: { _ in },
            popToRootAction: popToRootAction
        )

        navigationActionHandler.coordinator = coordinator
        let options = MainCoordinator.Options(userWalletModel: userWalletModel)
        coordinator.start(with: options)

        setState(.main(coordinator))
    }
}

// MARK: - ScanDismissOptions

enum ScanDismissOptions {
    case main(UserWalletModel)
    case onboarding(OnboardingInput)
}
