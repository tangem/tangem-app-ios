//
//  WelcomeV2ImportSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemMobileWalletBackup

final class WelcomeV2ImportSheetViewModel: ObservableObject, Identifiable {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter
    @Injected(\.welcomeV2AnalyticsProvider) private var analytics: WelcomeV2AnalyticsProvider

    let id = UUID()
    let title: String
    let subtitle: String?
    let onBack: () -> Void
    let onClose: () -> Void

    /// The `Sheet` value this sheet reports in analytics; lives on the sheet so it can't
    /// outlive it, unlike a mirror flag on the coordinator.
    let analyticsSheet: Analytics.ParameterValue = .welcomeV2ImportExisting

    @Published private(set) var items: [WelcomeV2ImportSheetItem]

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
            WelcomeV2ImportSheetItem(
                id: ItemID.recovery,
                title: Localization.hwCloudBackupRestoreUseRecoveryPhrase,
                isEnabled: true,
                isLoading: false,
                action: input.onRecoveryPhrase
            ),
            WelcomeV2ImportSheetItem(
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

extension WelcomeV2ImportSheetViewModel {
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

private extension WelcomeV2ImportSheetViewModel {
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
            AppLogger.error("WelcomeV2 iCloud backup load failed", error: error)
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

        items[index] = WelcomeV2ImportSheetItem(
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

extension WelcomeV2ImportSheetViewModel {
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

extension WelcomeV2ImportSheetViewModel {
    /// Item ids double as the key for accessibility identifiers in the view.
    enum ItemID {
        static let recovery = "recovery"
        static let iCloud = "icloud"
    }
}

private extension WelcomeV2ImportSheetViewModel {
    enum Constants {
        static let loadingTimeout: Duration = .seconds(1)
    }
}
