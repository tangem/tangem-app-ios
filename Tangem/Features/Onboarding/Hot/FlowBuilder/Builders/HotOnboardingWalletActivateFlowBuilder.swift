//
//  HotOnboardingWalletActivateFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

final class HotOnboardingWalletActivateFlowBuilder: HotOnboardingFlowBuilder {
    let hasProgressBar = true

    private lazy var backAction = HotOnboardingFlowNavigation.Action(
        closure: weakify(self, forFunction: HotOnboardingWalletActivateFlowBuilder.goPreviousStep)
    )

    private let userWalletModel: UserWalletModel
    private weak var coordinator: HotOnboardingFlowRoutable?
    private weak var navigationDelegate: HotOnboardingFlowNavigationDelegate?

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        coordinator: HotOnboardingFlowRoutable,
        navigationDelegate: HotOnboardingFlowNavigationDelegate
    ) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        self.navigationDelegate = navigationDelegate
    }

    func buildSteps() -> [HotOnboardingFlowStep] {
        var steps: [HotOnboardingFlowStep] = []

        // [REDACTED_TODO_COMMENT]
        let isBackupNeeded = true
        if isBackupNeeded {
            let backupSteps = [
                makeSeedPhraseIntroStep(), makeSeedPhraseRecoveryStep(), makeSeedPhraseValidationStep(), makeSeedPhaseBackupContinueStep(),
            ]
            steps.append(contentsOf: backupSteps)
        }

        // [REDACTED_TODO_COMMENT]
        let isAccessCodeNeeded = true
        if isAccessCodeNeeded {
            steps.append(makeAccessCodeCreateStep())
        }

        steps.append(makeDoneStep())

        return steps
    }
}

// MARK: - Steps maker

private extension HotOnboardingWalletActivateFlowBuilder {
    func makeSeedPhraseIntroStep() -> HotOnboardingFlowStep {
        let closeAction = HotOnboardingFlowNavigation.Action(
            closure: weakify(self, forFunction: HotOnboardingWalletActivateFlowBuilder.closeOnboarding)
        )

        let navigation = HotOnboardingFlowNavigation(
            title: Localization.commonBackup,
            leadingItem: .close(closeAction),
            trailingItem: nil
        )

        let viewModel = HotOnboardingSeedPhraseIntroViewModel(delegate: self)
        let content = { HotOnboardingSeedPhraseIntroView(viewModel: viewModel) }

        return HotOnboardingFlowStep(navigation: navigation, content: content)
    }

    func makeSeedPhraseRecoveryStep() -> HotOnboardingFlowStep {
        let navigation = HotOnboardingFlowNavigation(
            title: Localization.commonBackup,
            leadingItem: .back(backAction),
            trailingItem: nil
        )

        let viewModel = HotOnboardingSeedPhraseRecoveryViewModel(delegate: self)
        let content = { HotOnboardingSeedPhraseRecoveryView(viewModel: viewModel) }

        return HotOnboardingFlowStep(navigation: navigation, content: content)
    }

    func makeSeedPhraseValidationStep() -> HotOnboardingFlowStep {
        let navigation = HotOnboardingFlowNavigation(
            title: Localization.commonBackup,
            leadingItem: .back(backAction),
            trailingItem: nil
        )

        let seedPhraseWords = getSeedPhraseWords()

        let viewModel = OnboardingSeedPhraseUserValidationViewModel(validationInput: .init(
            secondWord: seedPhraseWords[1],
            seventhWord: seedPhraseWords[6],
            eleventhWord: seedPhraseWords[10],
            createWalletAction: { [weak self] in
                self?.goNextStep()
            }
        ))

        let content = { OnboardingSeedPhraseUserValidationView(viewModel: viewModel) }

        return HotOnboardingFlowStep(navigation: navigation, content: content)
    }

    func makeSeedPhaseBackupContinueStep() -> HotOnboardingFlowStep {
        let navigation = HotOnboardingFlowNavigation(
            title: Localization.commonBackup,
            leadingItem: nil,
            trailingItem: nil
        )

        let viewModel = HotOnboardingSuccessViewModel(
            type: .seedPhaseBackupContinue,
            onAppear: {},
            onComplete: weakify(self, forFunction: HotOnboardingWalletActivateFlowBuilder.goNextStep)
        )

        let content = { HotOnboardingSuccessView(viewModel: viewModel) }

        return HotOnboardingFlowStep(navigation: navigation, content: content)
    }

    func makeAccessCodeCreateStep() -> HotOnboardingFlowStep {
        let skipAction = HotOnboardingFlowNavigation.Action { [weak self] in
            self?.coordinator?.openAccesCodeSkipAlert(
                onAllow: {
                    self?.goNextStep()
                }
            )
        }

        let navigation = HotOnboardingFlowNavigation(
            title: Localization.accessCodeNavtitle,
            leadingItem: nil,
            trailingItem: .skip(skipAction)
        )

        let viewModel = HotOnboardingAccessCodeCreateViewModel(delegate: self)
        let content = { HotOnboardingAccessCodeCreateView(viewModel: viewModel) }

        let backAction = HotOnboardingFlowNavigation.Action {
            viewModel.resetState()
        }

        viewModel.$state
            .sink { [weak navigationDelegate] accessCodeState in
                switch accessCodeState {
                case .accessCode:
                    navigationDelegate?.leadingItemChanged(to: nil)
                case .confirmAccessCode:
                    navigationDelegate?.leadingItemChanged(to: .back(backAction))
                }
            }
            .store(in: &bag)

        return HotOnboardingFlowStep(navigation: navigation, content: content)
    }

    func changeAccessCodeNavigationTrailingItem(state: HotOnboardingAccessCodeCreateViewModel.State) {
        switch state {
        case .accessCode:
            navigationDelegate?.leadingItemChanged(to: nil)
        case .confirmAccessCode:
            let action = HotOnboardingFlowNavigation.Action {}
            navigationDelegate?.leadingItemChanged(to: .back(action))
        }
    }

    func makeDoneStep() -> HotOnboardingFlowStep {
        let navigation = HotOnboardingFlowNavigation(
            title: Localization.commonDone,
            leadingItem: nil,
            trailingItem: nil
        )

        let viewModel = HotOnboardingSuccessViewModel(
            type: .walletReady,
            onAppear: weakify(self, forFunction: HotOnboardingWalletActivateFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingWalletActivateFlowBuilder.closeOnboarding)
        )

        let content = { HotOnboardingSuccessView(viewModel: viewModel) }

        return HotOnboardingFlowStep(navigation: navigation, content: content)
    }
}

// MARK: - Navigation

private extension HotOnboardingWalletActivateFlowBuilder {
    func goNextStep() {
        coordinator?.goNextStep()
    }

    func goPreviousStep() {
        coordinator?.goPreviousStep()
    }

    func openConfetti() {
        coordinator?.openConfetti()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - HotOnboardingSeedPhraseIntroDelegate

extension HotOnboardingWalletActivateFlowBuilder: HotOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        goNextStep()
    }
}

// MARK: - HotOnboardingSeedPhraseRecoveryDelegate

extension HotOnboardingWalletActivateFlowBuilder: HotOnboardingSeedPhraseRecoveryDelegate {
    func getSeedPhrase() -> [String] {
        getSeedPhraseWords()
    }

    func seedPhraseRecoveryContinue() {
        goNextStep()
    }
}

// MARK: - HotOnboardingAccessCodeDelegate

extension HotOnboardingWalletActivateFlowBuilder: HotOnboardingAccessCodeCreateDelegate {
    func isRequestBiometricsNeeded() -> Bool {
        true
    }

    func accessCodeComplete(accessCode: String) {
        // [REDACTED_TODO_COMMENT]
        goNextStep()
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension HotOnboardingWalletActivateFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        goNextStep()
    }
}

// MARK: - Private methods

private extension HotOnboardingWalletActivateFlowBuilder {
    func getSeedPhraseWords() -> [String] {
        // [REDACTED_TODO_COMMENT]
        return [
            "brother", "embrace", "piano", "income", "feature", "real",
            "bicycle", "stairs", "glimpse", "fan", "salon", "elder",
            // brother embrace piano income feature real bicycle stairs glimpse fan salon elder
        ]
    }
}
