//
//  MobileBackupSeedPhraseTypeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization
import TangemMobileWalletSdk
import TangemUIUtils

final class MobileBackupSeedPhraseTypeViewModel: ObservableObject {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    @Published private(set) var item: Item?

    private var isBackupNeeded: Bool {
        !backupStatusUtil.hasMnemonicBackup
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private lazy var authUtil = MobileAuthUtil(
        userWalletId: userWalletModel.userWalletId,
        config: userWalletModel.config,
        biometricsProvider: CommonUserWalletBiometricsProvider()
    )

    private let backupStatusUtil: MobileBackupStatusUtil
    private let userWalletModel: UserWalletModel
    private weak var delegate: MobileBackupSeedPhraseTypeDelegate?

    init(userWalletModel: UserWalletModel, delegate: MobileBackupSeedPhraseTypeDelegate) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
        backupStatusUtil = MobileBackupStatusUtil(userWalletModel: userWalletModel)
        item = makeItem()
        bind()
    }
}

// MARK: - Private methods

private extension MobileBackupSeedPhraseTypeViewModel {
    func bind() {
        userWalletModel.updatePublisher
            .withWeakCaptureOf(self)
            .compactMap { viewModel, result in
                viewModel.mapToItem(result: result)
            }
            .receiveOnMain()
            .assign(to: &$item)
    }

    func mapToItem(result: UpdateResult) -> Item? {
        switch result {
        case .configurationChanged: makeItem()
        case .nameDidChange: nil
        }
    }

    func makeItem() -> Item {
        let badge: BadgeView.Item = if isBackupNeeded {
            .noBackup
        } else {
            .done
        }

        let action = weakify(self, forFunction: MobileBackupSeedPhraseTypeViewModel.onItemTap)

        return Item(
            title: Localization.hwBackupSeedTitle,
            description: Localization.hwBackupSeedDescription,
            badge: badge,
            action: action
        )
    }

    func onItemTap() {
        logTapAnalytics()

        runTask(in: self) { viewModel in
            if viewModel.isBackupNeeded {
                await viewModel.handleSeedPhraseBackup()
            } else {
                await viewModel.handleSeedPhraseReveal()
            }
        }
    }

    func handleSeedPhraseBackup() async {
        await unlock { [weak self] context in
            await self?.openBackupFlow(context: context)
        }
    }

    func handleSeedPhraseReveal() async {
        await unlock { [weak self] context in
            await self?.openRevealFlow(context: context)
        }
    }
}

// MARK: - Unlocking

private extension MobileBackupSeedPhraseTypeViewModel {
    func unlock(handler: @escaping (MobileWalletContext) async -> Void) async {
        switch await unlock() {
        case .successful(let context):
            await handler(context)
        case .failed(let error):
            AppLogger.error("Unlock failed:", error: error)
            await showErrorAlert(error)
        case .canceled:
            break
        }
    }

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

// MARK: - Routing

private extension MobileBackupSeedPhraseTypeViewModel {
    func openBackupFlow(context: MobileWalletContext) async {
        await delegate?.onSeedPhraseBackup(context: context)
    }

    func openRevealFlow(context: MobileWalletContext) async {
        await delegate?.onSeedPhraseReveal(context: context)
    }
}

// MARK: - Alerts

@MainActor
private extension MobileBackupSeedPhraseTypeViewModel {
    func showErrorAlert(_ error: Error) {
        let alert = error.alertBinder
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - Analytics

private extension MobileBackupSeedPhraseTypeViewModel {
    func logTapAnalytics() {
        Analytics.log(.walletSettingsButtonRecoveryPhrase, contextParams: analyticsContextParams)
    }
}

// MARK: - Types

extension MobileBackupSeedPhraseTypeViewModel {
    struct Item {
        let title: String
        let description: String
        let badge: BadgeView.Item
        let action: () -> Void
    }
}
