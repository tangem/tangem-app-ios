//
//  MobileOnboardingImportICloudBackupFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemMobileWalletBackup

final class MobileOnboardingImportICloudBackupFlowBuilder: MobileOnboardingFlowBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private var hasBackupList: Bool { backups.count > 1 }

    private var selectedBackup: MobileWalletBackup?
    private var userWalletModel: UserWalletModel?

    private let backups: [MobileWalletBackup]
    private let source: MobileOnboardingFlowSource
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(
        backups: [MobileWalletBackup],
        source: MobileOnboardingFlowSource,
        coordinator: MobileOnboardingFlowRoutable
    ) {
        self.backups = backups
        self.source = source
        self.coordinator = coordinator
        super.init(hasProgressBar: false)
    }

    override func setupFlow() {
        if hasBackupList {
            let backupListStep = makeBackupListStep()
            append(step: backupListStep)
        }

        let backupStep = makeBackupStep()
        append(step: backupStep)

        let importCompletedStep = makeImportCompletedStep()
        append(step: importCompletedStep)

        let accessCodeStep = makeAccessCodeStep()
        append(step: accessCodeStep)

        if let pushNotificationsStep = makePushNotificationsStepIfNeeded() {
            append(step: pushNotificationsStep)
        }

        let doneStep = makeDoneStep()
        append(step: doneStep)
    }
}

// MARK: - Steps

private extension MobileOnboardingImportICloudBackupFlowBuilder {
    func makeBackupListStep() -> MobileOnboardingFlowStep {
        MobileOnboardingImportICloudBackupListStep(
            backups: backups,
            delegate: self
        )
    }

    func makeBackupStep() -> MobileOnboardingFlowStep {
        MobileOnboardingImportICloudBackupStep(
            dataSource: self,
            delegate: self
        )
    }

    func makeImportCompletedStep() -> MobileOnboardingFlowStep {
        MobileOnboardingSuccessStep(
            type: .walletImported,
            navigationTitle: Localization.walletImportTitle,
            onAppear: {},
            onComplete: weakify(self, forFunction: MobileOnboardingImportICloudBackupFlowBuilder.openNext)
        )
    }

    func makeAccessCodeStep() -> MobileOnboardingFlowStep {
        MobileOnboardingAccessCodeStep(
            mode: .create(canSkip: true),
            source: source,
            delegate: self
        )
    }

    func makePushNotificationsStepIfNeeded() -> MobileOnboardingFlowStep? {
        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)

        guard availabilityProvider.isAvailable else {
            return nil
        }

        let permissionManager = factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)
        return MobileOnboardingPushNotificationsStep(
            permissionManager: permissionManager,
            delegate: self
        )
    }

    func makeDoneStep() -> MobileOnboardingFlowStep {
        MobileOnboardingSuccessStep(
            type: .walletReady,
            navigationTitle: Localization.commonDone,
            onAppear: weakify(self, forFunction: MobileOnboardingImportICloudBackupFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: MobileOnboardingImportICloudBackupFlowBuilder.openMain)
        )
    }
}

// MARK: - Navigation

private extension MobileOnboardingImportICloudBackupFlowBuilder {
    func openNext() {
        next()
    }

    func openMain() {
        guard let userWalletModel else {
            return
        }
        coordinator?.openMain(userWalletModel: userWalletModel)
    }

    func openConfetti() {
        coordinator?.openConfetti()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - MobileOnboardingImportICloudBackupListDelegate

extension MobileOnboardingImportICloudBackupFlowBuilder: MobileOnboardingImportICloudBackupListDelegate {
    func onBackupSelect(_ backup: MobileWalletBackup) {
        selectedBackup = backup
        openNext()
    }

    func onBackupListClose() {
        closeOnboarding()
    }
}

// MARK: - MobileOnboardingImportICloudBackupDataSource

extension MobileOnboardingImportICloudBackupFlowBuilder: MobileOnboardingImportICloudBackupDataSource {
    func getBackup() -> MobileWalletBackup? {
        hasBackupList ? selectedBackup : backups.first
    }
}

// MARK: - MobileOnboardingImportICloudBackupDelegate

extension MobileOnboardingImportICloudBackupFlowBuilder: MobileOnboardingImportICloudBackupDelegate {
    func didImportBackup(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        openNext()
    }

    func onBackupClose() {
        if hasBackupList {
            back()
        } else {
            closeOnboarding()
        }
    }
}

// MARK: - MobileOnboardingAccessCodeDelegate

extension MobileOnboardingImportICloudBackupFlowBuilder: MobileOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        openNext()
    }

    func onAccessCodeClose() {}
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension MobileOnboardingImportICloudBackupFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        openNext()
    }
}
