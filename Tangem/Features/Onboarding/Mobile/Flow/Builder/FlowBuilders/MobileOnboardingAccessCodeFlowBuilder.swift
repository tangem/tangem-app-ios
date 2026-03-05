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
        super.init(hasProgressBar: false)
    }

    override func setupFlow() {
        let mode: MobileOnboardingAccessCodeViewModel.Mode = userWalletModel.config.userWalletAccessCodeStatus
            .hasAccessCode ? .change(context) : .create(canSkip: false)

        let accessCodeStep = MobileOnboardingAccessCodeStep(
            mode: mode,
            source: source,
            delegate: self
        )
        append(step: accessCodeStep)

        let doneStep = MobileOnboardingSuccessStep(
            type: .walletReady,
            navigationTitle: Localization.commonDone,
            onAppear: {},
            onComplete: weakify(self, forFunction: MobileOnboardingAccessCodeFlowBuilder.closeOnboarding)
        )
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

// MARK: - MobileOnboardingAccessCodeDelegate

extension MobileOnboardingAccessCodeFlowBuilder: MobileOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        openNext()
    }

    func onAccessCodeClose() {
        coordinator?.closeOnboarding()
    }
}
