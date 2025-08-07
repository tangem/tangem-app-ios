//
//  HotOnboardingAccessCodeFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class HotOnboardingAccessCodeFlowBuilder: HotOnboardingFlowBuilder {
    private let userWalletModel: UserWalletModel
    private let needRequestBiometrics: Bool
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        needRequestBiometrics: Bool,
        coordinator: HotOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.needRequestBiometrics = needRequestBiometrics
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let createAccessCodeStep = HotOnboardingCreateAccessCodeStep(delegate: self)
            .configureNavBar(
                title: Localization.accessCodeNavtitle,
                leadingAction: navBarCloseAction
            )
        append(step: createAccessCodeStep)

        let doneStep = HotOnboardingSuccessStep(
            type: .walletReady,
            onAppear: {},
            onComplete: weakify(self, forFunction: HotOnboardingAccessCodeFlowBuilder.closeOnboarding)
        )
        doneStep.configureNavBar(title: Localization.commonDone)
        append(step: doneStep)
    }
}

// MARK: - Navigation

private extension HotOnboardingAccessCodeFlowBuilder {
    func openNext() {
        next()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - Private methods

private extension HotOnboardingAccessCodeFlowBuilder {
    var navBarCloseAction: HotOnboardingFlowNavBarAction {
        HotOnboardingFlowNavBarAction.close(handler: { [weak self] in
            self?.closeOnboarding()
        })
    }
}

// MARK: - HotOnboardingAccessCodeDelegate

extension HotOnboardingAccessCodeFlowBuilder: HotOnboardingAccessCodeCreateDelegate {
    func isRequestBiometricsNeeded() -> Bool {
        needRequestBiometrics
    }

    func isAccessCodeCanSkipped() -> Bool {
        false
    }

    func accessCodeComplete(accessCode: String) {
        // [REDACTED_TODO_COMMENT]
        openNext()
    }

    func accessCodeSkipped() {}
}
