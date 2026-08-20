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
        let dismiss: () -> Void = { [weak self] in
            self?.actionSheetViewModel = nil
        }

        actionSheetViewModel = WelcomeV2CreateWalletActionFactory().make(
            callbacks: .init(
                onHardware: dismiss,
                onMobile: dismiss,
                onClose: dismiss
            )
        )
    }

    func openExistingWallet() {
        presentExistingWallet()
    }
}

// MARK: - Sheet presentation

private extension WelcomeV2Coordinator {
    func presentExistingWallet() {
        let dismiss: () -> Void = { [weak self] in
            self?.actionSheetViewModel = nil
        }

        let openImport: () -> Void = { [weak self] in
            self?.presentImportWallet()
        }

        actionSheetViewModel = WelcomeV2ExistingWalletActionFactory().make(
            callbacks: .init(
                onHardware: dismiss,
                onImport: openImport,
                onClose: dismiss
            )
        )
    }

    func presentImportWallet() {
        guard let parent = actionSheetViewModel else { return }

        let dismiss: () -> Void = { [weak self] in
            self?.actionSheetViewModel = nil
        }

        let goBack: () -> Void = { [weak parent] in
            parent?.pushedImportSheet = nil
        }

        parent.pushedImportSheet = WelcomeV2ImportWalletFactory().make(
            callbacks: .init(
                onRecoveryPhrase: dismiss,
                onICloudBackup: dismiss,
                onBack: goBack,
                onClose: dismiss
            )
        )
    }
}
