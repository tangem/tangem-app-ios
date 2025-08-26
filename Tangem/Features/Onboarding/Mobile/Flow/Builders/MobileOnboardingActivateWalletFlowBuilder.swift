//
//  MobileOnboardingActivateWalletFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingFlowBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)
    }

    private var isAccessCodeNeeded: Bool {
        userWalletModel.config.hasFeature(.userWalletAccessCode) && !MobileAccessCodeSkipHelper.has(userWalletId: userWalletModel.userWalletId)
    }

    private let userWalletModel: UserWalletModel
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(userWalletModel: UserWalletModel, coordinator: MobileOnboardingFlowRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        if isBackupNeeded {
            setupSeedPhraseBackupFlow()
        }

        if isAccessCodeNeeded {
            setupAccessCodeFlow()
        }

        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForAfterLogin(using: pushNotificationsInteractor)

        if availabilityProvider.isAvailable {
            let permissionManager = factory.makePermissionManagerForAfterLogin(using: pushNotificationsInteractor)
            let pushNotificationsStep = MobileOnboardingPushNotificationsStep(
                permissionManager: permissionManager,
                delegate: self
            )
            pushNotificationsStep.configureNavBar(title: Localization.onboardingTitleNotifications)
            append(step: pushNotificationsStep)
        }

        let doneStep = MobileOnboardingSuccessStep(
            type: .walletReady,
            onAppear: weakify(self, forFunction: MobileOnboardingActivateWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: MobileOnboardingActivateWalletFlowBuilder.closeOnboarding)
        )
        doneStep.configureNavBar(title: Localization.commonDone)
        append(step: doneStep)

        setupProgress()
    }
}

// MARK: - Flows

private extension MobileOnboardingActivateWalletFlowBuilder {
    func setupSeedPhraseBackupFlow() {
        let seedPhraseIntroStep = MobileOnboardingSeedPhraseIntroStep(delegate: self)
            .configureNavBar(
                title: Localization.commonBackup,
                leadingAction: .close(handler: { [weak self] in
                    Analytics.log(.backupNoticeCanceled)

                    self?.closeOnboarding()
                })
            )
        append(step: seedPhraseIntroStep)

        let userWalletId = userWalletModel.userWalletId

        let seedPhraseRecoveryStep = MobileOnboardingSeedPhraseRecoveryStep(userWalletId: userWalletId, delegate: self)
        seedPhraseRecoveryStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        append(step: seedPhraseRecoveryStep)

        let seedPhraseValidationStep = MobileOnboardingSeedPhraseValidationStep(
            userWalletId: userWalletModel.userWalletId,
            delegate: self
        )
        seedPhraseValidationStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        append(step: seedPhraseValidationStep)

        let doneStep = MobileOnboardingSuccessStep(
            type: .seedPhaseBackupContinue,
            onAppear: {},
            onComplete: { [weak self] in
                Analytics.log(.settingAccessCodeStarted)

                self?.openNext()
            }
        )
        doneStep.configureNavBar(title: Localization.commonBackup)
        append(step: doneStep)
    }

    func setupAccessCodeFlow() {
        let accessCodeStep = MobileOnboardingAccessCodeStep(delegate: self)
        accessCodeStep.configureNavBar(title: Localization.accessCodeNavtitle)
        append(step: accessCodeStep)
    }
}

// MARK: - Navigation

private extension MobileOnboardingActivateWalletFlowBuilder {
    func openNext() {
        next()
    }

    func openMain() {
        coordinator?.openMain(userWalletModel: userWalletModel)
    }

    func openConfetti() {
        coordinator?.openConfetti()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - MobileOnboardingSeedPhraseIntroDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        openNext()
    }
}

// MARK: - MobileOnboardingSeedPhraseRecoveryDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        openNext()
    }
}

// MARK: - MobileOnboardingSeedPhraseValidationDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingSeedPhraseValidationDelegate {
    func didValidateSeedPhrase() {
        Analytics.log(event: .backupFinished, params: [.cardsCount: String(0)])
        userWalletModel.update(type: .mnemonicBackupCompleted)
        openNext()
    }
}

// MARK: - MobileOnboardingAccessCodeDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        openNext()
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension MobileOnboardingActivateWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}
