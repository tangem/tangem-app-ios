////
////  HotOnboardingSeedPhraseBackupFlowBuilder.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2025 Tangem AG. All rights reserved.
////
//
// import Foundation
// import TangemLocalization
//
// final class HotOnboardingSeedPhraseBackupFlowBuilder: HotOnboardingFlowBuilder {
//    let hasProgressBar = false
//
//    private lazy var backAction = HotOnboardingFlowNavigation.Action(
//        closure: weakify(self, forFunction: HotOnboardingSeedPhraseBackupFlowBuilder.goPreviousStep)
//    )
//
//    private let userWalletModel: UserWalletModel
//    private weak var coordinator: HotOnboardingFlowRoutable?
//
//    init(userWalletModel: UserWalletModel, coordinator: HotOnboardingFlowRoutable) {
//        self.userWalletModel = userWalletModel
//        self.coordinator = coordinator
//    }
//
//    func buildSteps() -> [HotOnboardingFlowStep] {
//        [makeSeedPhraseIntroStep(), makeSeedPhraseRecoveryStep(), makeSeedPhraseValidationStep(), makeDoneStep()]
//    }
// }
//
//// MARK: - Steps maker
//
// private extension HotOnboardingSeedPhraseBackupFlowBuilder {
//    func makeSeedPhraseIntroStep() -> HotOnboardingFlowStep {
//        let closeAction = HotOnboardingFlowNavigation.Action(
//            closure: weakify(self, forFunction: HotOnboardingSeedPhraseBackupFlowBuilder.closeOnboarding)
//        )
//
//        let navigation = HotOnboardingFlowNavigation(
//            title: Localization.commonBackup,
//            leadingItem: .close(closeAction),
//            trailingItem: nil
//        )
//
//        let viewModel = HotOnboardingSeedPhraseIntroViewModel(delegate: self)
//        let content = { HotOnboardingSeedPhraseIntroView(viewModel: viewModel) }
//
//        return HotOnboardingFlowStep(navigation: navigation, content: content)
//    }
//
//    func makeSeedPhraseRecoveryStep() -> HotOnboardingFlowStep {
//        let navigation = HotOnboardingFlowNavigation(
//            title: Localization.commonBackup,
//            leadingItem: .back(backAction),
//            trailingItem: nil
//        )
//
//        let viewModel = HotOnboardingSeedPhraseRecoveryViewModel(delegate: self)
//        let content = { HotOnboardingSeedPhraseRecoveryView(viewModel: viewModel) }
//
//        return HotOnboardingFlowStep(navigation: navigation, content: content)
//    }
//
//    func makeSeedPhraseValidationStep() -> HotOnboardingFlowStep {
//        let navigation = HotOnboardingFlowNavigation(
//            title: Localization.commonBackup,
//            leadingItem: .back(backAction),
//            trailingItem: nil
//        )
//
//        let seedPhraseWords = getSeedPhraseWords()
//
//        let viewModel = OnboardingSeedPhraseUserValidationViewModel(validationInput: .init(
//            secondWord: seedPhraseWords[1],
//            seventhWord: seedPhraseWords[6],
//            eleventhWord: seedPhraseWords[10],
//            createWalletAction: { [weak self] in
//                self?.goNextStep()
//            }
//        ))
//
//        let content = { OnboardingSeedPhraseUserValidationView(viewModel: viewModel) }
//
//        return HotOnboardingFlowStep(navigation: navigation, content: content)
//    }
//
//    func makeDoneStep() -> HotOnboardingFlowStep {
//        let navigation = HotOnboardingFlowNavigation(
//            title: Localization.commonDone,
//            leadingItem: nil,
//            trailingItem: nil
//        )
//
//        let viewModel = HotOnboardingSuccessViewModel(
//            type: .seedPhaseBackupFinish,
//            onAppear: weakify(self, forFunction: HotOnboardingSeedPhraseBackupFlowBuilder.openConfetti),
//            onComplete: weakify(self, forFunction: HotOnboardingSeedPhraseBackupFlowBuilder.closeOnboarding)
//        )
//
//        let content = { HotOnboardingSuccessView(viewModel: viewModel) }
//
//        return HotOnboardingFlowStep(navigation: navigation, content: content)
//    }
// }
//
//// MARK: - Navigation
//
// private extension HotOnboardingSeedPhraseBackupFlowBuilder {
//    func goNextStep() {
//        coordinator?.goNextStep()
//    }
//
//    func goPreviousStep() {
//        coordinator?.goPreviousStep()
//    }
//
//    func openConfetti() {
//        coordinator?.openConfetti()
//    }
//
//    func closeOnboarding() {
//        coordinator?.closeOnboarding()
//    }
// }
//
//// MARK: - HotOnboardingSeedPhraseIntroDelegate
//
// extension HotOnboardingSeedPhraseBackupFlowBuilder: HotOnboardingSeedPhraseIntroDelegate {
//    func seedPhraseIntroContinue() {
//        goNextStep()
//    }
// }
//
//// MARK: - HotOnboardingSeedPhraseRecoveryDelegate
//
// extension HotOnboardingSeedPhraseBackupFlowBuilder: HotOnboardingSeedPhraseRecoveryDelegate {
//    func getSeedPhrase() -> [String] {
//        getSeedPhraseWords()
//    }
//
//    func seedPhraseRecoveryContinue() {
//        goNextStep()
//    }
// }
//
//// MARK: - Private methods
//
// private extension HotOnboardingSeedPhraseBackupFlowBuilder {
//    func getSeedPhraseWords() -> [String] {
//        // [REDACTED_TODO_COMMENT]
//        return [
//            "brother", "embrace", "piano", "income", "feature", "real",
//            "bicycle", "stairs", "glimpse", "fan", "salon", "elder",
//            // brother embrace piano income feature real bicycle stairs glimpse fan salon elder
//        ]
//    }
// }
