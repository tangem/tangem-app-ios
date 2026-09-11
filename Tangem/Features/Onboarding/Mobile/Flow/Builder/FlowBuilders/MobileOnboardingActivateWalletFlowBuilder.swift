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
import TangemMobileWalletSdk

final class MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingFlowBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private var isBackupNeeded: Bool {
        switch source {
        case .main:
            return backupStatusUtil.isBackupNeeded
        case .backup:
            return !backupStatusUtil.hasMnemonicBackup
        case .importWallet, .hardwareWallet, .walletSettings:
            assertionFailure("Unpredictable source for mobile activating flow: \(source)")
            return false
        }
    }

    private lazy var isAccessCodeNeeded: Bool = userWalletModel.config.userWalletAccessCodeStatus == .none

    private lazy var isPushNotificationsNeeded: Bool = {
        let availabilityProvider = pushNotificationsFactory.makeAvailabilityProviderForAfterLogin(using: pushNotificationsInteractor)
        return availabilityProvider.isAvailable
    }()

    private var isWalletReadyNeeded: Bool {
        isAccessCodeNeeded || isPushNotificationsNeeded
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let pushNotificationsFactory = PushNotificationsHelpersFactory()

    private let backupStatusUtil: MobileBackupStatusUtil
    private let userWalletModel: UserWalletModel
    private let source: MobileOnboardingFlowSource
    private let context: MobileWalletContext
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        context: MobileWalletContext,
        coordinator: MobileOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.context = context
        self.coordinator = coordinator
        backupStatusUtil = MobileBackupStatusUtil(userWalletModel: userWalletModel)
        super.init(hasProgressBar: true)
    }

    override func setupFlow() {
        if isBackupNeeded {
            setupSeedPhraseBackupFlow()
        }

        if isAccessCodeNeeded {
            setupAccessCodeFlow()
        }

        if isPushNotificationsNeeded {
            setupPushNotificationsFlow()
        }

        if isWalletReadyNeeded {
            let step = makeWalletReadyStep()
            append(step: step)
        }
    }
}

// MARK: - Flows

private extension MobileOnboardingActivateWalletFlowBuilder {
    func setupSeedPhraseBackupFlow() {
        let seedPhraseIntroStep = MobileOnboardingSeedPhraseIntroStep(
            userWalletModel: userWalletModel,
            source: source,
            delegate: self
        )
        append(step: seedPhraseIntroStep)

        let seedPhraseRecoveryStep = MobileOnboardingSeedPhraseRecoveryStep(
            userWalletModel: userWalletModel,
            source: source,
            context: context,
            delegate: self
        )
        append(step: seedPhraseRecoveryStep)

        let seedPhraseValidationStep = MobileOnboardingSeedPhraseValidationStep(
            userWalletModel: userWalletModel,
            source: source,
            context: context,
            delegate: self
        )
        append(step: seedPhraseValidationStep)

        let backupContinueStep = MobileOnboardingSuccessStep(
            type: .backupContinue,
            navigationTitle: Localization.commonBackup,
            onAppear: { [weak self] in
                self?.logBackupCompletedScreenOpenedAnalytics()
            },
            onComplete: { [weak self] in
                guard let self else { return }

                if hasNext {
                    openNext()
                } else {
                    closeOnboarding()
                }
            }
        )
        append(step: backupContinueStep)
    }

    func setupAccessCodeFlow() {
        let accessCodeStep = MobileOnboardingAccessCodeStep(
            mode: .create(canSkip: true),
            source: source,
            delegate: self
        )
        append(step: accessCodeStep)
    }

    func setupPushNotificationsFlow() {
        let permissionManager = pushNotificationsFactory.makePermissionManagerForAfterLogin(using: pushNotificationsInteractor)
        let pushNotificationsStep = MobileOnboardingPushNotificationsStep(
            permissionManager: permissionManager,
            delegate: self
        )
        append(step: pushNotificationsStep)
    }
}

// MARK: - Steps

private extension MobileOnboardingActivateWalletFlowBuilder {
    func makeWalletReadyStep() -> MobileOnboardingFlowStep {
        MobileOnboardingSuccessStep(
            type: .walletReady,
            navigationTitle: Localization.commonDone,
            onAppear: weakify(self, forFunction: MobileOnboardingActivateWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: MobileOnboardingActivateWalletFlowBuilder.closeOnboarding)
        )
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

    func seedPhraseIntroClose() {
        logSeedPhraseIntroCloseAnalytics()
        closeOnboarding()
    }
}

// MARK: - MobileOnboardingSeedPhraseRecoveryDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        openNext()
    }

    func onSeedPhraseRecoveryBack() {
        back()
    }
}

// MARK: - MobileOnboardingSeedPhraseValidationDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingSeedPhraseValidationDelegate {
    func didValidateSeedPhrase() {
        logSeedPhraseValidatedAnalytics()
        userWalletModel.update(type: .mnemonicBackupCompleted)
        openNext()
    }

    func onSeedPhraseValidationBack() {
        back()
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

    func onAccessCodeClose() {}
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension MobileOnboardingActivateWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}

// MARK: - Analytics

private extension MobileOnboardingActivateWalletFlowBuilder {
    func logSeedPhraseIntroCloseAnalytics() {
        Analytics.log(.backupNoticeCanceled, contextParams: analyticsContextParams)
    }

    func logSeedPhraseValidatedAnalytics() {
        var params: [Analytics.ParameterKey: String] = [.cardsCount: String(0)]
        if FeatureProvider.isAvailable(.mobileWalletBackup) {
            params[.backupType] = Analytics.ParameterValue.backupTypeManual.rawValue
        }

        Analytics.log(
            event: .backupFinished,
            params: params,
            contextParams: analyticsContextParams
        )
    }

    func logBackupCompletedScreenOpenedAnalytics() {
        var params = source.analyticsParams
        if FeatureProvider.isAvailable(.mobileWalletBackup) {
            params[.backupType] = .backupTypeManual
        }

        Analytics.log(
            .walletSettingsBackupCompleteScreen,
            params: params,
            contextParams: analyticsContextParams
        )
    }
}
