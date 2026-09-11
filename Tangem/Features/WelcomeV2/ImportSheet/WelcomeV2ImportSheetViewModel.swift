//
//  WelcomeV2ImportSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMobileWalletBackup

final class WelcomeV2ImportSheetViewModel: ObservableObject, Identifiable {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    let id = UUID()
    let title: String
    let subtitle: String?
    let onBack: () -> Void
    let onClose: () -> Void

    @Published private(set) var items: [WelcomeV2ImportSheetItem]

    private let onRecoveryPhrase: () -> Void
    private let onICloudBackup: ([MobileWalletBackup]) -> Void
    private let backupManager: MobileWalletBackupManager

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
                id: Constants.recoveryItemId,
                title: "Import recovery phrase",
                isEnabled: true,
                isLoading: false,
                action: input.onRecoveryPhrase
            ),
            WelcomeV2ImportSheetItem(
                id: Constants.iCloudItemId,
                title: "Restore iCloud backup",
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
        switch loadResult {
        case .success(let backups) where backups.isEmpty:
            updateICloudItem(state: .notFound)
        case .success(let backups):
            updateICloudItem(state: .enabled(backups: backups))
        case .failure(let error):
            updateICloudItem(state: .retry)
            if !silent {
                alertPresenter.present(alert: error.alertBinder)
            }
        }
    }

    @MainActor
    func updateICloudItem(state: ICloudBackupState) {
        guard let index = items.firstIndex(where: { $0.id == Constants.iCloudItemId }) else { return }

        items[index] = WelcomeV2ImportSheetItem(
            id: Constants.iCloudItemId,
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
            case .loading, .enabled: "Restore iCloud backup"
            case .notFound: "iCloud backup not found"
            case .retry: "Retry iCloud backup"
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
    }
}

// MARK: - Constants

private extension WelcomeV2ImportSheetViewModel {
    enum Constants {
        static let recoveryItemId = "recovery"
        static let iCloudItemId = "icloud"
        static let loadingTimeout: Duration = .seconds(1)
    }
}
