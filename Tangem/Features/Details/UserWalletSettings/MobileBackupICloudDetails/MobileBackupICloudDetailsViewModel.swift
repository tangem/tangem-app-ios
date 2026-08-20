//
//  MobileBackupICloudDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemFoundation
import TangemMobileWalletBackup
import TangemLocalization
import TangemUIUtils
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileBackupICloudDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    var description: Description {
        makeDescription()
    }

    let removeActionTitle = Localization.hwCloudBackupSheetRemove

    private static let dateFormatter = DateFormatter(dateFormat: "MMMM d yyyy, h:mm a")

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let backup: MobileWalletBackup
    private let userWalletModel: UserWalletModel
    private let onDelete: () -> Void
    private weak var coordinator: MobileBackupICloudDetailsRoutable?

    init(
        backup: MobileWalletBackup,
        userWalletModel: UserWalletModel,
        coordinator: MobileBackupICloudDetailsRoutable,
        onDelete: @escaping () -> Void
    ) {
        self.backup = backup
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        self.onDelete = onDelete
    }
}

// MARK: - Internal methods

extension MobileBackupICloudDetailsViewModel {
    func onFirstAppear() {
        logScreenOpenedAnalytics()
    }

    func onRemoveTap() {
        runTask(in: self) { viewModel in
            await viewModel.showDeletionAlert()
        }
    }

    func onCloseTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }
}

// MARK: - Private methods

private extension MobileBackupICloudDetailsViewModel {
    func makeDescription() -> Description {
        let title = Localization.hwCloudBackupRemoveTitle(MobileBackupConstants.iCloudServiceName, backup.metadata.walletName)
        let formattedDate = backup.metadata.createdAt.map { Self.dateFormatter.string(from: $0) } ?? .empty
        let subtitle = Localization.hwCloudBackupSheetBackupTime(formattedDate)
        return Description(
            title: title,
            subtitle: subtitle
        )
    }

    func onDeleteConfirm() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
        onDelete()
    }
}

// MARK: - Alerts

@MainActor
private extension MobileBackupICloudDetailsViewModel {
    func showDeletionAlert() {
        logDeletionRequestAnalytics()
        let alert = AlertBuilder.makeAlert(
            title: Localization.hwBackupCloudDeleteConfirmTitle(MobileBackupConstants.iCloudServiceName),
            message: Localization.hwCloudBackupDeleteConfirmMessage(MobileBackupConstants.iCloudServiceName),
            primaryButton: .destructive(
                Text(Localization.commonDelete),
                action: weakify(self, forFunction: MobileBackupICloudDetailsViewModel.onDeleteConfirm)
            ),
            secondaryButton: .cancel(Text(Localization.commonCancel))
        )
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - Routing

@MainActor
private extension MobileBackupICloudDetailsViewModel {
    func close() {
        coordinator?.closeMobileBackupICloudDetails()
    }
}

// MARK: - Analytics

private extension MobileBackupICloudDetailsViewModel {
    func logScreenOpenedAnalytics() {
        Analytics.log(.walletSettingsCloudBackupDetailsScreen, contextParams: analyticsContextParams)
    }

    func logDeletionRequestAnalytics() {
        Analytics.log(.walletSettingsCloudBackupDeletionRequest, contextParams: analyticsContextParams)
    }
}

// MARK: - Types

extension MobileBackupICloudDetailsViewModel {
    struct Description {
        let title: String
        let subtitle: String
    }
}
