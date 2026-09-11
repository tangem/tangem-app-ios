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

    let title = Localization.hwCloudBackupRestoreNavtitleV2(MobileBackupConstants.iCloudServiceName)
    let description = Localization.hwCloudBackupCellDescription(MobileBackupConstants.iCloudServiceName)

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private lazy var backupManager: MobileWalletBackupManager = CommonMobileWalletBackupManager(destination: .iCloud)
    private lazy var backupStatusUtil = MobileBackupStatusUtil(userWalletModel: userWalletModel)

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
        runTask(in: self) { viewModel in
            if FeatureProvider.isAvailable(.mobileWalletBackup) {
                viewModel.bind()
                await viewModel.calculateState()
            } else {
                await viewModel.setupUnavailableState()
            }
        }
    }

    func bind() {
        userWalletModel.updatePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                viewModel.handleWalletUpdate(result: result)
            }
            .store(in: &bag)
    }

    func calculateState() async {
        if backupStatusUtil.hasICloudBackup {
            await hasBackupFlow()
        } else {
            await noBackupFlow()
        }
    }

    func handleWalletUpdate(result: UpdateResult) {
        switch result {
        case .configurationChanged:
            runTask(in: self) { viewModel in
                await viewModel.calculateState()
            }
        case .nameDidChange:
            break
        }
    }

    func updateBackupDeletedStatus() {
        userWalletModel.update(type: .iCloudBackupDeleted)
    }

    func delete(backup: MobileWalletBackup) {
        runTask(in: self) { viewModel in
            await viewModel.deletingFlow(backup: backup)
        }
    }
}

// MARK: - Flows

private extension MobileBackupICloudTypeViewModel {
    func hasBackupFlow() async {
        await loadingFlow()
    }

    func noBackupFlow() async {
        await setupIncompleteState()
    }

    func loadingFlow() async {
        await setupProcessingState()

        do {
            if let backup = try await backupManager.loadBackup(walletId: userWalletModel.userWalletId) {
                await setupDoneState(backup: backup)
            } else {
                await setupRequirementState(reason: .backupNotFound)
            }

        } catch {
            AppLogger.error("Failed to load the cloud backup details:", error: error)

            switch error {
            case WalletBackupStorageError.storageUnavailable:
                await setupRequirementState(reason: .iCloudUnavailable)
            default:
                await setupRequirementState(reason: .backupNotFound)
            }
        }
    }

    func deletingFlow(backup: MobileWalletBackup) async {
        await setupProcessingState()

        do {
            try await backupManager.deleteBackup(backup)

            logBackupDeletedAnalytics()
            updateBackupDeletedStatus()

            await delegate?.onICloudBackupDeleted()

        } catch {
            AppLogger.error("Failed to delete the cloud backup:", error: error)
            logDeletionErrorAnalytics(error)

            await calculateState()
        }
    }
}

// MARK: - States

private extension MobileBackupICloudTypeViewModel {
    func setupProcessingState() async {
        await setup(state: .processing)
    }

    func setupDoneState(backup: MobileWalletBackup) async {
        let item = DoneItem(
            badge: .done,
            action: { [weak self] in
                self?.logTapAnalytics()
                self?.onBackupDetails(backup: backup)
            }
        )
        await setup(state: .done(item))
    }

    func setupIncompleteState() async {
        let item = IncompleteItem(
            badge: .noBackup,
            action: { [weak self] in
                self?.logTapAnalytics()
                self?.onBackupCreate()
            }
        )
        await setup(state: .incomplete(item))
    }

    func setupUnavailableState() async {
        let item = UnavailableItem(action: { [weak self] in
            self?.onUnavailableTap()
        })
        await setup(state: .unavailable(item))
    }

    func setupRequirementState(reason: RequirementReason) async {
        let item = RequirementItem(
            badge: .actionRequired,
            action: { [weak self] in
                self?.logTapAnalytics()
                self?.onRequirement(reason: reason)
            }
        )
        await setup(state: .requirement(item))
    }

    func onRequirement(reason: RequirementReason) {
        runTask(in: self) { viewModel in
            switch reason {
            case .iCloudUnavailable:
                await viewModel.onStorageUnavailable()
            case .backupNotFound:
                await viewModel.onBackupNotFound()
            }
        }
    }

    func onUnavailableTap() {
        logTapAnalytics()
        runTask(in: self) { viewModel in
            await viewModel.showUnavailableAlert()
        }
    }

    @MainActor
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

    func onStorageUnavailable() async {
        await delegate?.onICloudBackupStorageUnavailable(output: self)
    }

    func onBackupNotFound() async {
        await delegate?.onICloudBackupNotFound(output: self)
    }

    func onBackupCreate() {
        runTask(in: self) { viewModel in
            await viewModel.delegate?.onICloudBackupCreate()
        }
    }
}

// MARK: - MobileBackupStorageUnavailableOutput

extension MobileBackupICloudTypeViewModel: MobileBackupStorageUnavailableOutput {
    func didRequestRetry() {
        runTask(in: self) { viewModel in
            await viewModel.calculateState()
        }
    }
}

// MARK: - MobileBackupNotFoundOutput

extension MobileBackupICloudTypeViewModel: MobileBackupNotFoundOutput {
    func didRequestCreate() {
        onBackupCreate()
    }

    func didRequestForget() {
        updateBackupDeletedStatus()
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
        case processing
        case done(DoneItem)
        case incomplete(IncompleteItem)
        case requirement(RequirementItem)
        case unavailable(UnavailableItem)
    }

    enum RequirementReason {
        case iCloudUnavailable
        case backupNotFound
    }

    struct DoneItem {
        let badge: BadgeView.Item
        let action: () -> Void
    }

    struct IncompleteItem {
        let badge: BadgeView.Item
        let action: () -> Void
    }

    struct RequirementItem {
        let badge: BadgeView.Item
        let action: () -> Void
    }

    struct UnavailableItem {
        let action: () -> Void
    }
}
