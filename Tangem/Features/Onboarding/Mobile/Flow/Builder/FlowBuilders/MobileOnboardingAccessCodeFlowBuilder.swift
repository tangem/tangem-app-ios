//
//  MobileOnboardingAccessCodeFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemMobileWalletSdk

final class MobileOnboardingAccessCodeFlowBuilder: MobileOnboardingFlowBuilder {
    private let userWalletModel: UserWalletModel
    private let context: MobileWalletContext
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        context: MobileWalletContext,
        coordinator: MobileOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.context = context
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let accessCodeStep = MobileOnboardingAccessCodeStep(context: context, delegate: self)
            .configureNavBar(
                title: Localization.accessCodeNavtitle,
                leadingAction: navBarCloseAction
            )
        append(step: accessCodeStep)

        let doneStep = MobileOnboardingSuccessStep(
            type: .walletReady,
            onAppear: {},
            onComplete: weakify(self, forFunction: MobileOnboardingAccessCodeFlowBuilder.closeOnboarding)
        )
        doneStep.configureNavBar(title: Localization.commonDone)
        append(step: doneStep)
    }
}

// MARK: - Navigation

private extension MobileOnboardingAccessCodeFlowBuilder {
    func openNext() {
        next()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - Private methods

private extension MobileOnboardingAccessCodeFlowBuilder {
    var navBarCloseAction: MobileOnboardingFlowNavBarAction {
        MobileOnboardingFlowNavBarAction.close(handler: { [weak self] in
            self?.closeOnboarding()
        })
    }
}

// MARK: - MobileOnboardingAccessCodeDelegate

extension MobileOnboardingAccessCodeFlowBuilder: MobileOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        openNext()
    }
}
