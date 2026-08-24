//
//  MobileOnboardingImportWalletFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class MobileOnboardingImportWalletFlowBuilder: MobileOnboardingFlowBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private var userWalletModel: UserWalletModel?

    private let source: MobileOnboardingFlowSource
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(source: MobileOnboardingFlowSource, coordinator: MobileOnboardingFlowRoutable) {
        self.source = source
        self.coordinator = coordinator
        super.init(hasProgressBar: true)
    }

    override func setupFlow() {
        let importWalletStep = MobileOnboardingImportWalletStep(delegate: self)
        append(step: importWalletStep)

        let importCompletedStep = MobileOnboardingSuccessStep(
            type: .walletImported,
            navigationTitle: Localization.walletImportTitle,
            onAppear: { [weak self] in
                self?.logImportCompletedScreenOpenedAnalytics()
            },
            onComplete: weakify(self, forFunction: MobileOnboardingImportWalletFlowBuilder.openNext)
        )
        append(step: importCompletedStep)

        let accessCodeStep = MobileOnboardingAccessCodeStep(
            mode: .create(canSkip: true),
            source: source,
            delegate: self
        )
        append(step: accessCodeStep)

        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)

        if availabilityProvider.isAvailable {
            let permissionManager = factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)
            let pushNotificationsStep = MobileOnboardingPushNotificationsStep(
                permissionManager: permissionManager,
                delegate: self
            )
            append(step: pushNotificationsStep)
        }

        let doneStep = MobileOnboardingSuccessStep(
            type: .walletReady,
            navigationTitle: Localization.commonDone,
            onAppear: weakify(self, forFunction: MobileOnboardingImportWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: MobileOnboardingImportWalletFlowBuilder.openMain)
        )
        append(step: doneStep)
    }
}

// MARK: - Analytics

private extension MobileOnboardingImportWalletFlowBuilder {
    func logImportCompletedScreenOpenedAnalytics() {
        guard FeatureProvider.isAvailable(.mobileWalletBackup) else {
            return
        }

        let contextData = userWalletModel?.analyticsContextData ?? .mobileWallet

        Analytics.log(
            event: .importCompletedScreenOpened,
            params: [.backupType: Analytics.ParameterValue.backupTypeManual.rawValue],
            contextParams: .custom(contextData)
        )
    }
}

// MARK: - Navigation

private extension MobileOnboardingImportWalletFlowBuilder {
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

// MARK: - MobileOnboardingSeedPhraseImportDelegate

extension MobileOnboardingImportWalletFlowBuilder: MobileOnboardingSeedPhraseImportDelegate {
    func didImportSeedPhrase(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        next()
    }

    func onSeedPhraseImportBack() {
        closeOnboarding()
    }
}

// MARK: - MobileOnboardingAccessCodeDelegate

extension MobileOnboardingImportWalletFlowBuilder: MobileOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        next()
    }

    func onAccessCodeClose() {}
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension MobileOnboardingImportWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}
