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
        super.init()
    }

    override func setupFlow() {
        let importWalletStep = MobileOnboardingImportWalletStep(delegate: self)
            .configureNavBar(
                title: Localization.walletImportTitle,
                leadingAction: .back(handler: { [weak self] in
                    self?.closeOnboarding()
                })
            )
        append(step: importWalletStep)

        let importCompletedStep = MobileOnboardingSuccessStep(
            type: .walletImported,
            onAppear: {},
            onComplete: weakify(self, forFunction: MobileOnboardingImportWalletFlowBuilder.openNext)
        )
        importCompletedStep.configureNavBar(title: Localization.walletImportTitle)
        append(step: importCompletedStep)

        let accessCodeStep = MobileOnboardingAccessCodeStep(mode: .create(canSkip: true), source: source, delegate: self)
            .configureNavBar(title: Localization.accessCodeNavtitle)
        append(step: accessCodeStep)

        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)

        if availabilityProvider.isAvailable {
            let permissionManager = factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)
            let pushNotificationsStep = MobileOnboardingPushNotificationsStep(
                permissionManager: permissionManager,
                delegate: self
            )
            pushNotificationsStep.configureNavBar(title: Localization.onboardingTitleNotifications)
            append(step: pushNotificationsStep)
        }

        let doneStep = MobileOnboardingSuccessStep(
            type: .walletReady,
            onAppear: weakify(self, forFunction: MobileOnboardingImportWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: MobileOnboardingImportWalletFlowBuilder.openMain)
        )
        doneStep.configureNavBar(title: Localization.commonDone)
        append(step: doneStep)

        setupProgress()
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
}

// MARK: - MobileOnboardingAccessCodeDelegate

extension MobileOnboardingImportWalletFlowBuilder: MobileOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        next()
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension MobileOnboardingImportWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}
