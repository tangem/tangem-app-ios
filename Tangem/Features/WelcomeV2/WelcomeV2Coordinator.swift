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

    var dismissAction: Action<OutputOptions>
    var popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: WelcomeV2ViewModel?
    @Published var actionSheetViewModel: WelcomeV2ActionSheetViewModel?
    @Published var hardwareWalletViewModel: WelcomeHardwareWalletViewModel?

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

    func openMain(with userWalletModel: UserWalletModel) {
        hardwareWalletViewModel = nil
        dismiss(with: .main(userWalletModel))
    }

    func openOnboarding(with input: OnboardingInput) {
        hardwareWalletViewModel = nil
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
                onMobile: dismissSheet,
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
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.sheetTransitionDelay) { [weak self] in
            self?.presentHardwareWallet()
        }
    }
}
