//
//  WelcomeV2Coordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemMobileWalletBackup

final class WelcomeV2Coordinator: CoordinatorObject {
    @Injected(\.welcomeV2BackgroundVideoProvider)
    private var videoProvider: WelcomeV2BackgroundVideoProviding

    @Injected(\.alertPresenter)
    private var alertPresenter: AlertPresenter

    var dismissAction: Action<OutputOptions>
    var popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: WelcomeV2ViewModel?
    @Published var actionSheetViewModel: WelcomeV2ActionSheetViewModel?
    @Published var hardwareWalletViewModel: WelcomeHardwareWalletViewModel?
    @Published var mobileCreateWalletCoordinator: MobileCreateWalletCoordinator?
    @Published var importOnboardingCoordinator: OnboardingCoordinator?
    @Published var legalWebViewModel: WebViewContainerViewModel?

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        AppLogger.debug("WelcomeV2Coordinator deinit")
    }

    func start(with options: Options) {
        rootViewModel = WelcomeV2ViewModel(
            coordinator: self,
            videoProvider: videoProvider
        )
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

    func openHardwareWallet() {
        presentHardwareWallet()
    }

    func closeHardwareWallet() {
        hardwareWalletViewModel = nil
    }

    func openLegal(url: URL) {
        legalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: "",
            withCloseButton: true,
            withNavigationBar: false
        )
    }

    func openMain(with userWalletModel: UserWalletModel) {
        hardwareWalletViewModel = nil
        mobileCreateWalletCoordinator = nil
        importOnboardingCoordinator = nil
        dismiss(with: .main(userWalletModel))
    }

    func openOnboarding(with input: OnboardingInput) {
        hardwareWalletViewModel = nil
        mobileCreateWalletCoordinator = nil
        importOnboardingCoordinator = nil
        dismiss(with: .onboarding(input))
    }
}

// MARK: - Sheet presentation

private extension WelcomeV2Coordinator {
    static let sheetTransitionDelay: TimeInterval = 0.35

    func presentCreateWallet() {
        actionSheetViewModel = WelcomeV2CreateWalletActionFactory().make(
            callbacks: .init(
                onHardware: dismissSheetThenPresentHardware,
                onMobile: dismissSheetThenPresentMobile,
                onClose: dismissSheet
            )
        )
    }

    func presentExistingWallet() {
        actionSheetViewModel = WelcomeV2ExistingWalletActionFactory().make(
            callbacks: .init(
                onHardware: dismissSheetThenPresentHardware,
                onImport: presentImportWalletIfAvailable,
                onClose: dismissSheet
            )
        )
    }

    func presentImportWalletIfAvailable() {
        guard mobileWalletFeatureProvider.isAvailable else {
            actionSheetViewModel = nil
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Self.sheetTransitionDelay))
                guard let self else { return }
                alertPresenter.present(alert: mobileWalletFeatureProvider.makeRestrictionAlert())
            }
            return
        }

        guard FeatureProvider.isAvailable(.mobileWalletBackup) else {
            actionSheetViewModel = nil
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Self.sheetTransitionDelay))
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
                try? await Task.sleep(for: .seconds(Self.sheetTransitionDelay))
                let input = MobileOnboardingInput(flow: .walletImport(source: .importWallet))
                self?.presentImportOnboarding(options: .mobileInput(input))
            }
        }

        let openICloudBackup: ([MobileWalletBackup]) -> Void = { [weak self] backups in
            self?.actionSheetViewModel = nil
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Self.sheetTransitionDelay))
                let input = MobileOnboardingInput(flow: .iCloudBackupImport(backups: backups, source: .importWallet))
                self?.presentImportOnboarding(options: .mobileInput(input))
            }
        }

        parent.pushedImportSheet = WelcomeV2ImportWalletFactory().make(
            callbacks: .init(
                onRecoveryPhrase: openRecoveryPhrase,
                onICloudBackup: openICloudBackup,
                onBack: goBack,
                onClose: dismissSheet
            )
        )
    }

    func presentHardwareWallet() {
        hardwareWalletViewModel = WelcomeHardwareWalletViewModel(coordinator: self)
    }

    func dismissSheet() {
        actionSheetViewModel = nil
    }

    /// SwiftUI cannot present a fullScreenCover or a navigation push while a sheet is up,
    /// so we close the sheet first and wait for the dismiss animation before continuing.
    func dismissSheetThenPresentHardware() {
        actionSheetViewModel = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Self.sheetTransitionDelay))
            self?.presentHardwareWallet()
        }
    }

    func dismissSheetThenPresentMobile() {
        actionSheetViewModel = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Self.sheetTransitionDelay))
            self?.presentCreateMobileWallet()
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
