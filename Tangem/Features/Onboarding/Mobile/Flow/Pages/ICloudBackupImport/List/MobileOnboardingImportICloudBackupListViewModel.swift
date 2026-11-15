//
//  MobileOnboardingImportICloudBackupListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemMobileWalletBackup

final class MobileOnboardingImportICloudBackupListViewModel: ObservableObject {
    let navigationTitle = Localization.hwCloudBackupRestoreNavtitleV2(MobileBackupConstants.iCloudServiceName)

    var items: [Item] {
        makeItems()
    }

    let hint = Localization.hwCloudBackupRestoreAllAddedHint(MobileBackupConstants.iCloudServiceName)

    var isHintVisible: Bool {
        backups.allSatisfy(backupImportUtil.isAdded)
    }

    private static let dateFormatter = DateFormatter(dateFormat: "MMMM d yyyy, h:mm a")

    private let backupImportUtil = MobileBackupImportUtil()

    private let backups: [MobileWalletBackup]
    private weak var delegate: MobileOnboardingImportICloudBackupListDelegate?

    init(
        backups: [MobileWalletBackup],
        delegate: MobileOnboardingImportICloudBackupListDelegate
    ) {
        self.backups = backups
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension MobileOnboardingImportICloudBackupListViewModel {
    func onBackTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }

    func onAppear() {
        logScreenOpenedAnalytics()
    }
}

// MARK: - Private methods

private extension MobileOnboardingImportICloudBackupListViewModel {
    func makeItems() -> [Item] {
        backups
            .sorted {
                ($0.metadata.createdAt ?? .distantPast) > ($1.metadata.createdAt ?? .distantPast)
            }
            .map(makeItem)
    }

    func makeItem(backup: MobileWalletBackup) -> Item {
        let description = backup.metadata.createdAt.map {
            Self.dateFormatter.string(from: $0)
        } ?? .empty

        return Item(
            title: backup.metadata.walletName,
            description: description,
            state: makeItemState(backup: backup)
        )
    }

    func makeItemState(backup: MobileWalletBackup) -> Item.State {
        if backupImportUtil.isAdded(backup) {
            return .added(badgeTitle: Localization.commonAdded)
        }

        let action: () -> Void = { [weak self] in
            self?.onBackupTap(backup)
        }
        return .available(action: action)
    }

    func onBackupTap(_ backup: MobileWalletBackup) {
        runTask(in: self) { viewModel in
            await viewModel.onBackupSelect(backup)
        }
    }
}

// MARK: - Routing

@MainActor
private extension MobileOnboardingImportICloudBackupListViewModel {
    func close() {
        delegate?.onBackupListClose()
    }

    func onBackupSelect(_ backup: MobileWalletBackup) {
        delegate?.onBackupSelect(backup)
    }
}

// MARK: - Analytics

private extension MobileOnboardingImportICloudBackupListViewModel {
    func logScreenOpenedAnalytics() {
        Analytics.log(
            event: .selectCloudBackupScreen,
            params: [.backupsCount: "\(backups.count)"],
            contextParams: .custom(.mobileWallet)
        )
    }
}

// MARK: - Types

extension MobileOnboardingImportICloudBackupListViewModel {
    struct Item {
        let title: String
        let description: String
        let state: State

        enum State {
            case available(action: () -> Void)
            case added(badgeTitle: String)
        }
    }
}
