//
//  HotOnboardingAccessCodeFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemHotSdk

final class HotOnboardingAccessCodeFlowBuilder: HotOnboardingFlowBuilder {
    private let userWalletModel: UserWalletModel
    private let context: MobileWalletContext
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        context: MobileWalletContext,
        coordinator: HotOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.context = context
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let accessCodeStep = HotOnboardingAccessCodeStep(context: context, delegate: self)
            .configureNavBar(
                title: Localization.accessCodeNavtitle,
                leadingAction: navBarCloseAction
            )
        append(step: accessCodeStep)

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

extension HotOnboardingAccessCodeFlowBuilder: HotOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        openNext()
    }
}
