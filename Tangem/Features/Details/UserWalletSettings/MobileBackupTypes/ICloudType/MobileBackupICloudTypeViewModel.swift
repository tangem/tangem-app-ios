//
//  MobileBackupICloudTypeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemMobileWalletBackup
import TangemUIUtils
import TangemLocalization

final class MobileBackupICloudTypeViewModel: ObservableObject {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var state: State?

    let title = "iCloud backup"
    let description = "Save your wallet to iCloud for easy recovery. Data is securely encrypted."

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private lazy var backupManager: MobileWalletBackupManager = CommonMobileWalletBackupManager(destination: .iCloud)

    private let userWalletModel: UserWalletModel
    private weak var delegate: MobileBackupICloudTypeDelegate?

    private var bag: Set<AnyCancellable> = []

    init(userWalletModel: UserWalletModel, delegate: MobileBackupICloudTypeDelegate) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
        setup()
    }
}

// MARK: - Private methods

private extension MobileBackupICloudTypeViewModel {
    func setup() {
        guard FeatureProvider.isAvailable(.mobileWalletBackup) else {
            runTask(in: self) { viewModel in
                await viewModel.setupUnavailableState()
            }
            return
        }

        bind()
        load()
    }

    func bind() {
        userWalletModel.updatePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                viewModel.handleWalletUpdate(result: result)
            }
            .store(in: &bag)
    }

    func handleWalletUpdate(result: UpdateResult) {
        switch result {
        case .configurationChanged:
            load()
        case .nameDidChange:
            break
        }
    }

    func load() {
        runTask(in: self) { viewModel in
            await viewModel.loadingFlow()
        }
    }

    func loadingFlow() async {
        await setupLoadingState()

        do {
            guard let backup = try await backupManager.loadBackup(walletId: userWalletModel.userWalletId) else {
                throw WalletBackupStorageError.fileNotFound
            }
            await setupLoadedState(backup: backup)

        } catch {
            AppLogger.error("Failed to load the cloud backup details:", error: error)
            await setupLoadedState(backup: nil)
        }
    }

    func delete(backup: MobileWalletBackup) {
        runTask(in: self) { viewModel in
            await viewModel.deletingFlow(backup: backup)
        }
    }

    func deletingFlow(backup: MobileWalletBackup) async {
        await setupDeletingState()

        do {
            try await backupManager.deleteBackup(backup)

            logBackupDeletedAnalytics()
            userWalletModel.update(type: .iCloudBackupDeleted)

            await loadingFlow()

        } catch {
            AppLogger.error("Failed to delete the cloud backup:", error: error)
            logDeletionErrorAnalytics(error)

            await loadingFlow()
        }
    }
}

// MARK: - States

@MainActor
private extension MobileBackupICloudTypeViewModel {
    func setupLoadingState() {
        setup(state: .loading)
    }

    func setupLoadedState(backup: MobileWalletBackup?) {
        let badge: BadgeView.Item
        let action: () -> Void

        if let backup {
            badge = .done
            action = { [weak self] in
                self?.logTapAnalytics()
                self?.onBackupDetails(backup: backup)
            }
        } else {
            badge = .noBackup
            action = { [weak self] in
                self?.logTapAnalytics()
                self?.onBackup()
            }
        }

        let item = LoadedItem(
            badge: badge,
            action: action
        )

        setup(state: .loaded(item))
    }

    func setupDeletingState() {
        setup(state: .deleting)
    }

    func setupUnavailableState() {
        let action = weakify(self, forFunction: MobileBackupICloudTypeViewModel.onUnavailableTap)
        let item = UnavailableItem(action: action)
        setup(state: .unavailable(item))
    }

    func onUnavailableTap() {
        logTapAnalytics()
        showUnavailableAlert()
    }

    func setup(state: State) {
        self.state = state
    }
}

// MARK: - Alerts

@MainActor
private extension MobileBackupICloudTypeViewModel {
    func showUnavailableAlert() {
        let alert = AlertBuilder.makeAlert(
            title: Localization.hwBackupIcloudAlertTitle,
            message: Localization.hwBackupIcloudAlertMessage,
            primaryButton: .default(Text(Localization.commonOk))
        )
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - Routing

private extension MobileBackupICloudTypeViewModel {
    func onBackupDetails(backup: MobileWalletBackup) {
        runTask(in: self) { viewModel in
            await viewModel.onBackupDetails(backup: backup)
        }
    }

    func onBackupDetails(backup: MobileWalletBackup) async {
        await delegate?.onICloudBackupDetails(
            backup: backup,
            onDelete: { [weak self] in
                self?.delete(backup: backup)
            }
        )
    }

    func onBackup() {
        runTask { [delegate] in
            await delegate?.onICloudBackup()
        }
    }
}

// MARK: - Analytics

private extension MobileBackupICloudTypeViewModel {
    func logTapAnalytics() {
        Analytics.log(.walletSettingsButtonICloudBackup, contextParams: analyticsContextParams)
    }

    func logBackupDeletedAnalytics() {
        Analytics.log(.walletSettingsCloudBackupDeleted, contextParams: analyticsContextParams)
    }

    func logDeletionErrorAnalytics(_ error: Error) {
        Analytics.log(
            event: .walletSettingsCloudBackupDeletionError,
            params: MobileBackupStatusUtil.errorAnalyticsParams(error),
            contextParams: analyticsContextParams
        )
    }
}

// MARK: - Types

extension MobileBackupICloudTypeViewModel {
    enum State {
        case loading
        case loaded(LoadedItem)
        case deleting
        case unavailable(UnavailableItem)
    }

    struct LoadedItem {
        let badge: BadgeView.Item
        let action: () -> Void
    }

    struct UnavailableItem {
        let action: () -> Void
    }
}
