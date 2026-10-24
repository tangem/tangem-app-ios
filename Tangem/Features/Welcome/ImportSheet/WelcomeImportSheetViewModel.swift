//
//  WelcomeImportSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemMobileWalletBackup

final class WelcomeImportSheetViewModel: ObservableObject, Identifiable {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter
    @Injected(\.welcomeAnalyticsProvider) private var analytics: WelcomeAnalyticsProvider

    let id = UUID()
    let title: String
    let subtitle: String?
    let onBack: () -> Void
    let onClose: () -> Void

    /// The `Sheet` value this sheet reports in analytics; lives on the sheet so it can't
    /// outlive it, unlike a mirror flag on the coordinator.
    let analyticsSheet: Analytics.ParameterValue = .welcomeImportExisting

    @Published private(set) var items: [WelcomeImportSheetItem]

    private let onRecoveryPhrase: () -> Void
    private let onICloudBackup: ([MobileWalletBackup]) -> Void
    private let backupManager: MobileWalletBackupManager
    private var didLogImportRequest = false

    init(input: Input) {
        title = input.title
        subtitle = input.subtitle
        onBack = input.onBack
        onClose = input.onClose

        onRecoveryPhrase = input.onRecoveryPhrase
        onICloudBackup = input.onICloudBackup
        backupManager = input.backupManager

        items = [
            WelcomeImportSheetItem(
                id: ItemID.recovery,
                title: Localization.hwCloudBackupRestoreUseRecoveryPhrase,
                isEnabled: true,
                isLoading: false,
                action: input.onRecoveryPhrase
            ),
            WelcomeImportSheetItem(
                id: ItemID.iCloud,
                title: Localization.introductionImportIcloudRestore,
                isEnabled: false,
                isLoading: true,
                action: {}
            ),
        ]

        setupICloudBackupState(silent: true)
    }
}

// MARK: - Input

extension WelcomeImportSheetViewModel {
    struct Input {
        let title: String
        let subtitle: String?
        let onRecoveryPhrase: () -> Void
        let onICloudBackup: ([MobileWalletBackup]) -> Void
        let onBack: () -> Void
        let onClose: () -> Void
        let backupManager: MobileWalletBackupManager
    }
}

// MARK: - iCloud backup state

private extension WelcomeImportSheetViewModel {
    func setupICloudBackupState(silent: Bool) {
        runTask(in: self) { viewModel in
            await viewModel.markICloudLoading()
            let result = await Self.loadBackups(with: viewModel.backupManager)
            await viewModel.applyICloud(loadResult: result, silent: silent)
        }
    }

    static func loadBackups(
        with backupManager: MobileWalletBackupManager
    ) async -> Result<[MobileWalletBackup], Error> {
        do {
            let backups = try await Task.run(withTimeout: Constants.loadingTimeout) {
                try await backupManager.loadBackups()
            }
            return .success(backups)
        } catch {
            AppLogger.error("Welcome iCloud backup load failed", error: error)
            return .failure(error)
        }
    }

    @MainActor
    func markICloudLoading() {
        updateICloudItem(state: .loading)
    }

    @MainActor
    func applyICloud(loadResult: Result<[MobileWalletBackup], Error>, silent: Bool) {
        let state: ICloudBackupState = switch loadResult {
        case .success(let backups) where backups.isEmpty: .notFound
        case .success(let backups): .enabled(backups: backups)
        case .failure: .retry
        }

        updateICloudItem(state: state)

        if case .failure(let error) = loadResult, !silent {
            alertPresenter.present(alert: error.alertBinder)
        }

        logImportRequestOnce(state: state)
    }

    /// Matches the onboarding import screen: the request carries the resolved backup availability,
    /// so it waits for the first load result instead of firing on presentation.
    @MainActor
    func logImportRequestOnce(state: ICloudBackupState) {
        guard !didLogImportRequest else { return }
        didLogImportRequest = true

        analytics.logImportWalletRequest(hasCloudBackup: state.hasBackups)
    }

    @MainActor
    func updateICloudItem(state: ICloudBackupState) {
        guard let index = items.firstIndex(where: { $0.id == ItemID.iCloud }) else { return }

        items[index] = WelcomeImportSheetItem(
            id: ItemID.iCloud,
            title: state.title,
            isEnabled: state.isEnabled,
            isLoading: state.isLoading,
            action: iCloudAction(for: state)
        )
    }

    @MainActor
    func iCloudAction(for state: ICloudBackupState) -> () -> Void {
        switch state {
        case .enabled(let backups):
            return { [onICloudBackup] in onICloudBackup(backups) }
        case .retry:
            return { [weak self] in self?.setupICloudBackupState(silent: false) }
        case .loading, .notFound:
            return {}
        }
    }
}

// MARK: - Types

extension WelcomeImportSheetViewModel {
    enum ICloudBackupState {
        case loading
        case enabled(backups: [MobileWalletBackup])
        case notFound
        case retry

        var title: String {
            switch self {
            case .loading, .enabled: Localization.introductionImportIcloudRestore
            case .notFound: Localization.introductionImportIcloudNotFound
            case .retry: Localization.introductionImportIcloudRetry
            }
        }

        var isEnabled: Bool {
            switch self {
            case .enabled, .retry: true
            case .loading, .notFound: false
            }
        }

        var isLoading: Bool {
            switch self {
            case .loading: true
            case .enabled, .notFound, .retry: false
            }
        }

        var hasBackups: Bool {
            switch self {
            case .enabled: true
            case .loading, .notFound, .retry: false
            }
        }
    }
}

// MARK: - Constants

extension WelcomeImportSheetViewModel {
    /// Item ids double as the key for accessibility identifiers in the view.
    enum ItemID {
        static let recovery = "recovery"
        static let iCloud = "icloud"
    }
}

private extension WelcomeImportSheetViewModel {
    enum Constants {
        static let loadingTimeout: Duration = .seconds(1)
    }
}
