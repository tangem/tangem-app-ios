////
////  HotOnboardingSeedPhraseRevealFlowBuilder.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2025 Tangem AG. All rights reserved.
////
//
// import Foundation
// import TangemLocalization
//
// final class HotOnboardingSeedPhraseRevealFlowBuilder: HotOnboardingFlowBuilder {
//    let hasProgressBar = false
//
//    private lazy var closeAction = HotOnboardingFlowNavigation.Action(
//        closure: weakify(self, forFunction: HotOnboardingSeedPhraseRevealFlowBuilder.closeOnboarding)
//    )
//
//    private let userWalletModel: UserWalletModel
//    private let needAccessCodeValidation: Bool
//    private weak var coordinator: HotOnboardingFlowRoutable?
//
//    init(
//        userWalletModel: UserWalletModel,
//        needAccessCodeValidation: Bool,
//        coordinator: HotOnboardingFlowRoutable
//    ) {
//        self.userWalletModel = userWalletModel
//        self.needAccessCodeValidation = needAccessCodeValidation
//        self.coordinator = coordinator
//    }
//
//    func buildSteps() -> [HotOnboardingFlowStep] {
//        var steps: [HotOnboardingFlowStep] = []
//
//        if needAccessCodeValidation {
//            steps.append(makeAccessCodeValidateStep())
//        }
//
//        steps.append(makeSeedPhraseRevealStep())
//
//        return steps
//    }
// }
//
//// MARK: - Steps maker
//
// private extension HotOnboardingSeedPhraseRevealFlowBuilder {
//    func makeAccessCodeValidateStep() -> HotOnboardingFlowStep {
//        let navigation = HotOnboardingFlowNavigation(
//            title: "",
//            leadingItem: .close(closeAction),
//            trailingItem: nil
//        )
//
//        let manager = CommonHotAccessCodeManager(userWalletModel: userWalletModel, delegate: self)
//        let viewModel = HotAccessCodeViewModel(manager: manager)
//        let content = { HotAccessCodeView(viewModel: viewModel) }
//
//        return HotOnboardingFlowStep(navigation: navigation, content: content)
//    }
//
//    func makeSeedPhraseRevealStep() -> HotOnboardingFlowStep {
//        let navigation = HotOnboardingFlowNavigation(
//            title: Localization.commonBackup,
//            leadingItem: .close(closeAction),
//            trailingItem: nil
//        )
//
//        let viewModel = HotOnboardingSeedPhraseRevealViewModel(delegate: self)
//        let content = { HotOnboardingSeedPhraseRevealView(viewModel: viewModel) }
//
//        return HotOnboardingFlowStep(navigation: navigation, content: content)
//    }
// }
//
//// MARK: - Navigation
//
// private extension HotOnboardingSeedPhraseRevealFlowBuilder {
//    func goNextStep() {
//        coordinator?.goNextStep()
//    }
//
//    func closeOnboarding() {
//        coordinator?.closeOnboarding()
//    }
// }
//
//// MARK: - CommonHotAccessCodeManagerDelegate
//
// extension HotOnboardingSeedPhraseRevealFlowBuilder: CommonHotAccessCodeManagerDelegate {
//    func handleAccessCodeSuccessful(userWalletModel: UserWalletModel) {
//        goNextStep()
//    }
//
//    func handleAccessCodeDelete(userWalletModel: UserWalletModel) {
//        // [REDACTED_TODO_COMMENT]
//    }
// }
//
//// MARK: - HotOnboardingSeedPhraseRevealDelegate
//
// extension HotOnboardingSeedPhraseRevealFlowBuilder: HotOnboardingSeedPhraseRevealDelegate {
//    func getSeedPhrase() -> [String] {
//        getSeedPhraseWords()
//    }
// }
//
//// MARK: - Private methods
//
// private extension HotOnboardingSeedPhraseRevealFlowBuilder {
//    func getSeedPhraseWords() -> [String] {
//        // [REDACTED_TODO_COMMENT]
//        return [
//            "brother", "embrace", "piano", "income", "feature", "real",
//            "bicycle", "stairs", "glimpse", "fan", "salon", "elder",
//            // brother embrace piano income feature real bicycle stairs glimpse fan salon elder
//        ]
//    }
// }
