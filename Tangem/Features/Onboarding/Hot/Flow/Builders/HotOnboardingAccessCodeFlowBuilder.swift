//
//  HotOnboardingAccessCodeFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class HotOnboardingAccessCodeFlowBuilder: HotOnboardingFlowBuilder {
    private let userWalletModel: UserWalletModel
    private let needAccessCodeValidation: Bool
    private let needRequestBiometrics: Bool
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        needAccessCodeValidation: Bool,
        needRequestBiometrics: Bool,
        coordinator: HotOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.needAccessCodeValidation = needAccessCodeValidation
        self.needRequestBiometrics = needRequestBiometrics
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        if needAccessCodeValidation {
            let manager = CommonHotAccessCodeManager(userWalletModel: userWalletModel, delegate: self)
            let validateAccessCodeStep = HotOnboardingValidateAccessCodeStep(manager: manager)
            flow.append(validateAccessCodeStep)
        }

        let createAccessCodeStep = HotOnboardingCreateAccessCodeStep(coordinator: self, delegate: self)
        flow.append(createAccessCodeStep)

        let doneStep = HotOnboardingSuccessStep(
            type: .walletReady,
            onAppear: {},
            onComplete: weakify(self, forFunction: HotOnboardingAccessCodeFlowBuilder.closeOnboarding)
        )
        flow.append(doneStep)
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

// MARK: - CommonHotAccessCodeManagerDelegate

extension HotOnboardingAccessCodeFlowBuilder: CommonHotAccessCodeManagerDelegate {
    func handleAccessCodeSuccessful(userWalletModel: UserWalletModel) {
        openNext()
    }

    func handleAccessCodeDelete(userWalletModel: UserWalletModel) {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - HotOnboardingAccessCodeCreateRoutable

extension HotOnboardingAccessCodeFlowBuilder: HotOnboardingAccessCodeCreateRoutable {
    func openAccesCodeSkipAlert(onAllow: @escaping () -> Void) {}
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

    func accessCodeSkipped() {
        // [REDACTED_TODO_COMMENT]
        openNext()
    }
}
