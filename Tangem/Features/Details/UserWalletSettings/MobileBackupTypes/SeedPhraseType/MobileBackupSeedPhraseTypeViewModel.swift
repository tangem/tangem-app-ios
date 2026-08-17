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
        userWalletModel.config.hasFeature(.mnemonicBackup)
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let userWalletModel: UserWalletModel
    private weak var delegate: MobileBackupSeedPhraseTypeDelegate?

    init(userWalletModel: UserWalletModel, delegate: MobileBackupSeedPhraseTypeDelegate) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
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

    func handleSeedPhraseReveal() async {
        do {
            let context = try await unlock()
            await openRevealFlow(context: context)
        } catch where error.isCancellationError {
            AppLogger.error("Unlock is canceled", error: error)
        } catch {
            AppLogger.error("Unlock failed:", error: error)
            await showRevealErrorAlert(error)
        }
    }

    func onItemTap() {
        logTapAnalytics()

        runTask(in: self) { viewModel in
            if viewModel.isBackupNeeded {
                await viewModel.openBackupFlow()
            } else {
                await viewModel.handleSeedPhraseReveal()
            }
        }
    }
}

// MARK: - Unlocking

private extension MobileBackupSeedPhraseTypeViewModel {
    func unlock() async throws -> MobileWalletContext {
        let authUtil = MobileAuthUtil(
            userWalletId: userWalletModel.userWalletId,
            config: userWalletModel.config,
            biometricsProvider: CommonUserWalletBiometricsProvider()
        )
        let result = try await authUtil.unlock()

        switch result {
        case .successful(let context):
            return context

        case .canceled:
            throw CancellationError()

        case .userWalletNeedsToDelete:
            assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
            throw CancellationError()
        }
    }
}

// MARK: - Routing

private extension MobileBackupSeedPhraseTypeViewModel {
    func openBackupFlow() async {
        await delegate?.onSeedPhraseBackup()
    }

    func openRevealFlow(context: MobileWalletContext) async {
        await delegate?.onSeedPhraseReveal(context: context)
    }
}

// MARK: - Alerts

@MainActor
private extension MobileBackupSeedPhraseTypeViewModel {
    func showRevealErrorAlert(_ error: Error) {
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
