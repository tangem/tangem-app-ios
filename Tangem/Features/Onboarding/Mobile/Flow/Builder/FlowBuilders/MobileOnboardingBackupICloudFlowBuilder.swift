//
//  MobileOnboardingBackupICloudFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class MobileOnboardingBackupICloudFlowBuilder: MobileOnboardingFlowBuilder {
    private var isAccessCodeNeeded: Bool {
        userWalletModel.config.userWalletAccessCodeStatus == .none
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let userWalletModel: UserWalletModel
    private let source: MobileOnboardingFlowSource
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        coordinator: MobileOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.coordinator = coordinator
        super.init(hasProgressBar: true)
    }

    override func setupFlow() {
        append(step: makeBackupStep())

        if isAccessCodeNeeded {
            append(step: makeContinueStep())
            setupAccessCodeFlow()
        }

        append(step: makeDoneStep())
    }
}

// MARK: - Flows

private extension MobileOnboardingBackupICloudFlowBuilder {
    func setupAccessCodeFlow() {
        let accessCodeStep = MobileOnboardingAccessCodeStep(
            mode: .create(canSkip: true),
            source: source,
            delegate: self
        )
        append(step: accessCodeStep)
    }
}

// MARK: - Steps

private extension MobileOnboardingBackupICloudFlowBuilder {
    func makeBackupStep() -> MobileOnboardingFlowStep {
        MobileOnboardingICloudBackupStep(
            userWalletModel: userWalletModel,
            delegate: self
        )
    }

    func makeContinueStep() -> MobileOnboardingFlowStep {
        MobileOnboardingSuccessStep(
            type: .backupContinue,
            navigationTitle: Localization.hwBackupIcloudTitle,
            onAppear: {},
            onComplete: { [weak self] in
                self?.logSettingAccessCodeAnalytics()
                self?.openNext()
            }
        )
    }

    func makeDoneStep() -> MobileOnboardingFlowStep {
        MobileOnboardingSuccessStep(
            type: .walletReady,
            navigationTitle: Localization.commonDone,
            onAppear: weakify(self, forFunction: MobileOnboardingBackupICloudFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: MobileOnboardingBackupICloudFlowBuilder.completeOnboarding)
        )
    }
}

// MARK: - Navigation

private extension MobileOnboardingBackupICloudFlowBuilder {
    func openNext() {
        next()
    }

    func openConfetti() {
        coordinator?.openConfetti()
    }

    func completeOnboarding() {
        coordinator?.completeOnboarding()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - MobileOnboardingICloudBackupDelegate

extension MobileOnboardingBackupICloudFlowBuilder: MobileOnboardingICloudBackupDelegate {
    func onICloudBackupComplete() {
        logBackupCompletedScreenOpenedAnalytics()
        openNext()
    }

    func onICloudBackupClose() {
        closeOnboarding()
    }
}

// MARK: - MobileOnboardingAccessCodeDelegate

extension MobileOnboardingBackupICloudFlowBuilder: MobileOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        openNext()
    }

    func onAccessCodeClose() {}
}

// MARK: - Analytics

private extension MobileOnboardingBackupICloudFlowBuilder {
    func logBackupCompletedScreenOpenedAnalytics() {
        var params = source.analyticsParams
        params[.backupType] = .backupTypeCloud

        Analytics.log(
            .walletSettingsBackupCompleteScreen,
            params: params,
            contextParams: analyticsContextParams
        )
    }

    func logSettingAccessCodeAnalytics() {
        Analytics.log(.settingAccessCodeStarted, contextParams: analyticsContextParams)
    }
}
