//
//  MobileRemoveWalletNotificationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemUIUtils
import TangemMobileWalletSdk
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileRemoveWalletNotificationViewModel: ObservableObject {
    @Published var alert: AlertBinder?

    // [REDACTED_TODO_COMMENT]
    let title = "Forget this wallet?"

    var description: String {
        isBackupNeeded ?
            "If you forget this wallet without a backup, you’ll permanently lose access to your funds." :
            "A backup for this wallet exists. Review it before forgetting to make sure you can recover later."
    }

    lazy var removeAction: Action = makeRemoveAction()
    lazy var backupAction: Action = makeBackupAction()

    private let isBackupNeeded: Bool

    private let userWalletModel: UserWalletModel
    private weak var coordinator: MobileRemoveWalletNotificationRoutable?

    init(userWalletModel: UserWalletModel, coordinator: MobileRemoveWalletNotificationRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        isBackupNeeded = userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)
    }
}

// MARK: - Internal methods

extension MobileRemoveWalletNotificationViewModel {
    func onCloseTap() {
        runTask(in: self) { viewModel in
            await viewModel.dismiss()
        }
    }
}

// MARK: - Private methods

private extension MobileRemoveWalletNotificationViewModel {
    func makeRemoveAction() -> Action {
        // [REDACTED_TODO_COMMENT]
        Action(
            title: isBackupNeeded ? "Forget Anyway" : "Forget wallet",
            handler: weakify(self, forFunction: MobileRemoveWalletNotificationViewModel.removeHandler)
        )
    }

    func makeBackupAction() -> Action {
        Action(
            title: isBackupNeeded ? "Go to backup" : "View backup",
            handler: weakify(self, forFunction: MobileRemoveWalletNotificationViewModel.backupHandler)
        )
    }

    func removeHandler() {
        runTask(in: self) { viewModel in
            await viewModel.openRemoveWallet()
        }
    }

    func backupHandler() {
        runTask(in: self) { viewModel in
            if viewModel.isBackupNeeded {
                await viewModel.openSeedPhraseBackup()
            } else {
                await viewModel.seedPhraseReveal()
            }
        }
    }

    func seedPhraseReveal() async {
        do {
            let context = try await unlock()
            await openSeedPhraseReveal(context: context)
        } catch where error.isCancellationError {
            AppLogger.error("Unlock is canceled", error: error)
        } catch {
            AppLogger.error("Unlock failed:", error: error)
            await runOnMain {
                alert = error.alertBinder
            }
        }
    }
}

// MARK: - Unlocking

private extension MobileRemoveWalletNotificationViewModel {
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

// MARK: - Navigation

@MainActor
private extension MobileRemoveWalletNotificationViewModel {
    func openRemoveWallet() {
        coordinator?.openMobileRemoveWallet(userWalletId: userWalletModel.userWalletId)
    }

    func openSeedPhraseBackup() {
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(userWalletModel: userWalletModel))
        coordinator?.openMobileOnboardingFromRemoveWalletNotification(input: input)
    }

    func openSeedPhraseReveal(context: MobileWalletContext) {
        let input = MobileOnboardingInput(flow: .seedPhraseReveal(context: context))
        coordinator?.openMobileOnboardingFromRemoveWalletNotification(input: input)
    }

    func dismiss() {
        coordinator?.dismissMobileRemoveWalletNotification()
    }
}

// MARK: - Types

extension MobileRemoveWalletNotificationViewModel {
    struct Action {
        let title: String
        let handler: () -> Void
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileRemoveWalletNotificationViewModel: FloatingSheetContentViewModel {}
