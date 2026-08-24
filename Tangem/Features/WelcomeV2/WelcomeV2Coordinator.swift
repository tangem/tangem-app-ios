//
//  WelcomeV2Coordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

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
        dismiss(with: .main(userWalletModel))
    }

    func openOnboarding(with input: OnboardingInput) {
        hardwareWalletViewModel = nil
        mobileCreateWalletCoordinator = nil
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
                onImport: { [weak self] in self?.presentImportWallet() },
                onClose: dismissSheet
            )
        )
    }

    func presentImportWallet() {
        guard let parent = actionSheetViewModel else { return }

        let goBack: () -> Void = { [weak parent] in
            parent?.pushedImportSheet = nil
        }

        parent.pushedImportSheet = WelcomeV2ImportWalletFactory().make(
            callbacks: .init(
                onRecoveryPhrase: dismissSheet,
                onICloudBackup: dismissSheet,
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
}
