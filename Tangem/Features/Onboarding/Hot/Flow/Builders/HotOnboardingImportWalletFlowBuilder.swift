//
//  HotOnboardingImportWalletFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class HotOnboardingImportWalletFlowBuilder: HotOnboardingFlowBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private var userWalletModel: UserWalletModel?

    private weak var coordinator: HotOnboardingFlowRoutable?

    init(coordinator: HotOnboardingFlowRoutable) {
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let importWalletStep = HotOnboardingImportWalletStep(delegate: self)
            .configureNavBar(
                title: Localization.walletImportTitle,
                leadingAction: .back(handler: { [weak self] in
                    self?.closeOnboarding()
                })
            )
        append(step: importWalletStep)

        let importCompletedStep = HotOnboardingSuccessStep(
            type: .walletImported,
            onAppear: {},
            onComplete: weakify(self, forFunction: HotOnboardingImportWalletFlowBuilder.openNext)
        )
        importCompletedStep.configureNavBar(title: Localization.walletImportTitle)
        append(step: importCompletedStep)

        let accessCodeStep = HotOnboardingAccessCodeStep(delegate: self)
            .configureNavBar(title: Localization.accessCodeNavtitle)
        append(step: accessCodeStep)

        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)

        if availabilityProvider.isAvailable {
            let permissionManager = factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)
            let pushNotificationsStep = HotOnboardingPushNotificationsStep(
                permissionManager: permissionManager,
                delegate: self
            )
            pushNotificationsStep.configureNavBar(title: Localization.onboardingTitleNotifications)
            append(step: pushNotificationsStep)
        }

        let doneStep = HotOnboardingSuccessStep(
            type: .walletReady,
            onAppear: weakify(self, forFunction: HotOnboardingImportWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingImportWalletFlowBuilder.openMain)
        )
        doneStep.configureNavBar(title: Localization.commonDone)
        append(step: doneStep)

        setupProgress()
    }
}

// MARK: - Navigation

private extension HotOnboardingImportWalletFlowBuilder {
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

// MARK: - HotOnboardingSeedPhraseImportDelegate

extension HotOnboardingImportWalletFlowBuilder: HotOnboardingSeedPhraseImportDelegate {
    func didImportSeedPhrase(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        next()
    }
}

// MARK: - HotOnboardingAccessCodeDelegate

extension HotOnboardingImportWalletFlowBuilder: HotOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        next()
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension HotOnboardingImportWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}
