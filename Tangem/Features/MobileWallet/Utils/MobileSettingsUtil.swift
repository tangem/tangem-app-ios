//
//  MobileSettingsUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemFoundation
import TangemMobileWalletSdk

final class MobileSettingsUtil {
    @Injected(\.userWalletDismissedNotifications)
    private var dismissedNotifications: UserWalletDismissedNotifications

    private var isAccessCodeFeatureAvailable: Bool {
        userWalletConfig.isFeatureVisible(.userWalletAccessCode)
    }

    private var isAccessCodeNeeded: Bool {
        userWalletConfig.hasFeature(.userWalletAccessCode)
    }

    private var isBackupFeatureAvailable: Bool {
        userWalletConfig.isFeatureVisible(.userWalletBackup)
    }

    private var isUpgradeFeatureAvailable: Bool {
        userWalletConfig.isFeatureVisible(.userWalletUpgrade)
    }

    private var isBackupNeeded: Bool {
        userWalletConfig.hasFeature(.mnemonicBackup) && userWalletConfig.hasFeature(.iCloudBackup)
    }

    private var userWalletConfig: UserWalletConfig {
        userWalletModel.config
    }

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

// MARK: - Internal methods

extension MobileSettingsUtil {
    var walletSettings: [WalletSetting] {
        var settings: [WalletSetting] = []

        let isUpgradeNotificationDismissed = dismissedNotifications.has(
            userWalletId: userWalletModel.userWalletId,
            notification: .mobileUpgradeFromSettings
        )

        if isUpgradeFeatureAvailable, !isUpgradeNotificationDismissed {
            settings.append(.upgrade)
        }

        if isAccessCodeFeatureAvailable {
            settings.append(isAccessCodeNeeded ? .setAccessCode : .changeAccessCode)
        }

        if isBackupFeatureAvailable {
            settings.append(.backup(needsBackup: isBackupNeeded))
        }

        return settings
    }

    func calculateAccessCodeState() async -> AccessCodeState? {
        if isBackupNeeded {
            return .needsBackup
        }

        switch await unlock() {
        case .successful(let context):
            return .onboarding(context: context)
        case .canceled, .failed:
            return .none
        }
    }

    func calculateSeedPhraseState() async -> SeedPhraseState? {
        switch await unlock() {
        case .successful:
            return .onboarding
        case .canceled, .failed:
            return .none
        }
    }
}

// MARK: - Upgrade notification

extension MobileSettingsUtil {
    func makeUpgradeNotificationInput(
        onContext: @escaping (MobileWalletContext) -> Void,
        onDismiss: @escaping () -> Void
    ) -> NotificationViewInput {
        let factory = NotificationsFactory()

        let action: NotificationView.NotificationAction = { [weak self] _ in
            self?.onUpgradeNotificationTap(onContext: onContext)
        }

        let buttonAction: NotificationView.NotificationButtonTapAction = { _, _ in }

        let dismissAction: NotificationView.NotificationAction = { [weak self] _ in
            self?.onUpgradeNotificationDismiss(onDismiss: onDismiss)
        }

        return factory.buildNotificationInput(
            for: GeneralNotificationEvent.mobileUpgrade,
            action: action,
            buttonAction: buttonAction,
            dismissAction: dismissAction
        )
    }

    func onUpgradeNotificationTap(onContext: @escaping (MobileWalletContext) -> Void) {
        runTask(in: self) { viewModel in
            let unlockResult = await viewModel.unlock()

            switch unlockResult {
            case .successful(let context):
                onContext(context)
            case .canceled, .failed:
                break
            }
        }
    }

    func onUpgradeNotificationDismiss(onDismiss: @escaping () -> Void) {
        dismissedNotifications.add(userWalletId: userWalletModel.userWalletId, notification: .mobileUpgradeFromSettings)
        onDismiss()
    }
}

// MARK: - Unlocking

private extension MobileSettingsUtil {
    func unlock() async -> UnlockResult {
        do {
            let authUtil = MobileAuthUtil(
                userWalletId: userWalletModel.userWalletId,
                config: userWalletModel.config,
                biometricsProvider: CommonUserWalletBiometricsProvider()
            )
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                return .successful(context: context)

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
                return .failed
            }

        } catch {
            return .failed
        }
    }

    enum UnlockResult {
        case successful(context: MobileWalletContext)
        case canceled
        case failed
    }
}

// MARK: - Types

extension MobileSettingsUtil {
    enum WalletSetting {
        case setAccessCode
        case changeAccessCode
        case backup(needsBackup: Bool)
        case upgrade
    }

    enum AccessCodeState {
        case needsBackup
        case onboarding(context: MobileWalletContext)
    }

    enum SeedPhraseState {
        case onboarding
    }
}
