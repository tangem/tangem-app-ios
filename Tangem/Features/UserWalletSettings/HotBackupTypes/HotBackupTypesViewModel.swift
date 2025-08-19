//
//  HotBackupTypesViewModel.swift
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
import class TangemSdk.BiometricsUtil

final class HotBackupTypesViewModel: ObservableObject {
    @Published var backupItems: [BackupItem] = []
    @Published var alert: AlertBinder?

    let navTitle = Localization.commonBackup

    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup)
    }

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()
    private lazy var authUtil = HotAuthUtil(userWalletId: userWalletModel.userWalletId, config: userWalletModel.config)

    private let userWalletModel: UserWalletModel
    private weak var routable: HotBackupTypesRoutable?

    private var bag: Set<AnyCancellable> = []

    init(userWalletModel: UserWalletModel, routable: HotBackupTypesRoutable) {
        self.userWalletModel = userWalletModel
        self.routable = routable
        setup()
        bind()
    }
}

// MARK: - Private methods

private extension HotBackupTypesViewModel {
    func setup() {
        backupItems = makeBackupItems()
    }

    func bind() {
        userWalletModel.updatePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                viewModel.handleUpdate(result: result)
            }
            .store(in: &bag)
    }

    func handleUpdate(result: UpdateResult) {
        switch result {
        case .configurationChanged:
            setup()
        case .nameDidChange:
            break
        }
    }
}

// MARK: - Helpers

private extension HotBackupTypesViewModel {
    func makeBackupItems() -> [BackupItem] {
        [makeSeedPhraseBackupItem(), makeICloudBackupItem()]
    }

    func makeSeedPhraseBackupItem() -> BackupItem {
        let badge: BadgeView.Item = if isBackupNeeded {
            .noBackup
        } else {
            .done
        }

        let action = weakify(self, forFunction: HotBackupTypesViewModel.onSeedPhraseBackupTap)

        return BackupItem(
            title: Localization.hwBackupSeedTitle,
            description: Localization.hwBackupSeedDescription,
            badge: badge,
            isEnabled: true,
            action: action
        )
    }

    func makeICloudBackupItem() -> BackupItem {
        let badge = BadgeView.Item(title: Localization.commonComingSoon, style: .secondary)
        return BackupItem(
            title: Localization.hwBackupIcloudTitle,
            description: Localization.hwBackupIcloudDescription,
            badge: badge,
            isEnabled: false,
            action: {}
        )
    }

    func onSeedPhraseBackupTap() {
        if isBackupNeeded {
            openSeedPhraseBackup()
        } else {
            runTask(in: self) { viewModel in
                await viewModel.unlock()
            }
        }
    }
}

// MARK: - Unlocking

private extension HotBackupTypesViewModel {
    func unlock() async {
        do {
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                try await handleAccessCodeUnlockResult(context: context)

            case .canceled:
                return

            case .userWalletNeedsToDelete:
                // [REDACTED_TODO_COMMENT]
                return
            }
        } catch {
            AppLogger.error("Unlock with AccessCode failed:", error: error)
            await runOnMain {
                alert = error.alertBinder
            }
        }
    }

    func handleAccessCodeUnlockResult(context: MobileWalletContext) async throws {
        let encryptionKey = try mobileWalletSdk.userWalletEncryptionKey(context: context)

        guard
            let configEncryptionKey = UserWalletEncryptionKey(config: userWalletModel.config),
            encryptionKey.symmetricKey == configEncryptionKey.symmetricKey
        else {
            throw MobileWalletError.encryptionKeyMismatched
        }

        await openSeedPhraseReveal(context: context)
    }
}

// MARK: - Navigation

private extension HotBackupTypesViewModel {
    func openSeedPhraseBackup() {
        let input = HotOnboardingInput(flow: .seedPhraseBackup(userWalletModel: userWalletModel))
        routable?.openOnboarding(input: input)
    }

    @MainActor
    func openSeedPhraseReveal(context: MobileWalletContext) {
        let input = HotOnboardingInput(flow: .seedPhraseReveal(context: context))
        routable?.openOnboarding(input: input)
    }
}

// MARK: - Types

extension HotBackupTypesViewModel {
    struct BackupItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let badge: BadgeView.Item
        let isEnabled: Bool
        let action: () -> Void
    }
}
