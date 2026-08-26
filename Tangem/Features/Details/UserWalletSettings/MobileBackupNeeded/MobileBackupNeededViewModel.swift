//
//  MobileBackupNeededViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemMobileWalletSdk
import TangemUIUtils
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileBackupNeededViewModel {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    let title = Localization.hwBackupNeedTitle
    let description = Localization.hwBackupToSecureDescription
    let actionTitle = Localization.hwBackupNeedAction

    private lazy var authUtil = MobileAuthUtil(
        userWalletId: userWalletModel.userWalletId,
        config: userWalletModel.config,
        biometricsProvider: CommonUserWalletBiometricsProvider()
    )

    private let userWalletModel: UserWalletModel
    private let source: MobileOnboardingFlowSource
    private let onBackupFinished: () -> Void
    private weak var coordinator: MobileBackupNeededRoutable?

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        onBackupFinished: @escaping () -> Void,
        coordinator: MobileBackupNeededRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.onBackupFinished = onBackupFinished
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension MobileBackupNeededViewModel {
    func onCloseTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }

    func onBackupTap() {
        runTask(in: self) { viewModel in
            await viewModel.handleMobileBackup()
        }
    }
}

// MARK: - Private methods

private extension MobileBackupNeededViewModel {
    func handleMobileBackup() async {
        if FeatureProvider.isAvailable(.mobileWalletBackup) {
            await openMobileBackupTypes()
        } else {
            await handleMobileOnboarding()
        }
    }

    func handleMobileOnboarding() async {
        switch await unlock() {
        case .successful(let context):
            await openMobileOnboarding(context: context)
        case .failed(let error):
            AppLogger.error("Unlock failed:", error: error)
            await showErrorAlert(error)
        case .canceled:
            break
        }
    }
}

// MARK: - Unlocking

private extension MobileBackupNeededViewModel {
    func unlock() async -> UnlockResult {
        do {
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                return .successful(context: context)

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
                return .canceled
            }

        } catch {
            return .failed(error: error)
        }
    }

    enum UnlockResult {
        case successful(context: MobileWalletContext)
        case canceled
        case failed(error: Error)
    }
}

// MARK: - Alerts

@MainActor
private extension MobileBackupNeededViewModel {
    func showErrorAlert(_ error: Error) {
        let alert = error.alertBinder
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - Navigation

@MainActor
private extension MobileBackupNeededViewModel {
    func openMobileBackupTypes() {
        coordinator?.openMobileBackupTypesFromMobileBackupNeeded(userWalletModel: userWalletModel)
    }

    func openMobileOnboarding(context: MobileWalletContext) {
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(
            userWalletModel: userWalletModel,
            source: source,
            context: context
        ))
        coordinator?.openMobileOnboardingFromMobileBackupNeeded(
            input: input,
            onBackupFinished: onBackupFinished
        )
    }

    func close() {
        coordinator?.dismissMobileBackupNeeded()
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileBackupNeededViewModel: FloatingSheetContentViewModel {}
