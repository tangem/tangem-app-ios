//
//  MobileFinishActivationNeededViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import TangemMobileWalletSdk
import TangemLocalization
import TangemAssets
import TangemUIUtils
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileFinishActivationNeededViewModel {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    var description: String {
        isBackupNeeded ? Localization.hwActivationNeedDescription : Localization.hwActivationNeedWarningDescription
    }

    var iconType: ImageType {
        Assets.criticalAttentionShield
    }

    var iconBgColor: Color {
        Colors.Icon.warning
    }

    let title = Localization.hwActivationNeedTitle
    let laterTitle = Localization.commonLater
    let backupTitle = Localization.hwActivationNeedBackup

    private var isBackupNeeded: Bool {
        backupStatusUtil.isBackupNeeded
    }

    private lazy var authUtil = MobileAuthUtil(
        userWalletId: userWalletModel.userWalletId,
        config: userWalletModel.config,
        biometricsProvider: CommonUserWalletBiometricsProvider()
    )

    private let backupStatusUtil: MobileBackupStatusUtil
    private let userWalletModel: UserWalletModel
    private weak var coordinator: MobileFinishActivationNeededRoutable?

    init(userWalletModel: UserWalletModel, coordinator: MobileFinishActivationNeededRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        self.backupStatusUtil = MobileBackupStatusUtil(userWalletModel: userWalletModel)
    }
}

// MARK: - Internal methods

@MainActor
extension MobileFinishActivationNeededViewModel {
    func onCloseTap() {
        Analytics.log(.backupSkipped)
        close()
    }

    func onLaterTap() {
        Analytics.log(.backupSkipped)
        close()
    }

    func onBackupTap() {
        Analytics.log(.backupStarted)
        close()

        runTask(in: self) { viewModel in
            if viewModel.isBackupNeeded {
                viewModel.openMobileBackup()
            } else {
                await viewModel.handleMobileOnboarding()
            }
        }
    }

    func handleMobileOnboarding() async {
        switch await unlock() {
        case .successful(let context):
            openMobileBackupOnboarding(context: context)
        case .failed(let error):
            AppLogger.error("Unlock failed:", error: error)
            showErrorAlert(error)
        case .canceled:
            break
        }
    }
}

// MARK: - Unlocking

private extension MobileFinishActivationNeededViewModel {
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

// MARK: - Navigation

@MainActor
private extension MobileFinishActivationNeededViewModel {
    func openMobileBackup() {
        coordinator?.openMobileBackup(userWalletModel: userWalletModel)
    }

    func openMobileBackupOnboarding(context: MobileWalletContext) {
        coordinator?.openMobileBackupOnboarding(userWalletModel: userWalletModel, context: context)
    }

    func close() {
        coordinator?.dismissMobileFinishActivationNeeded()
    }
}

// MARK: - Alerts

@MainActor
private extension MobileFinishActivationNeededViewModel {
    func showErrorAlert(_ error: Error) {
        let alert = error.alertBinder
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileFinishActivationNeededViewModel: FloatingSheetContentViewModel {}
