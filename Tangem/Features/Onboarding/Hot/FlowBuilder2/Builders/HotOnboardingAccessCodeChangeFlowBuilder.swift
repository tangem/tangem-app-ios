////
////  HotOnboardingAccessCodeChangeFlowBuilder.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2025 Tangem AG. All rights reserved.
////
//
// import Foundation
// import Combine
// import TangemLocalization
//
// final class HotOnboardingAccessCodeChangeFlowBuilder: HotOnboardingFlowBuilder {
//    let hasProgressBar = false
//
//    private lazy var closeAction = HotOnboardingFlowNavigation.Action(
//        closure: weakify(self, forFunction: HotOnboardingAccessCodeChangeFlowBuilder.closeOnboarding)
//    )
//
//    private let userWalletModel: UserWalletModel
//    private let needAccessCodeValidation: Bool
//    private weak var coordinator: HotOnboardingFlowRoutable?
//    private weak var navigationDelegate: HotOnboardingFlowNavigationDelegate?
//
//    private var bag: Set<AnyCancellable> = []
//
//    init(
//        userWalletModel: UserWalletModel,
//        needAccessCodeValidation: Bool,
//        coordinator: HotOnboardingFlowRoutable,
//        navigationDelegate: HotOnboardingFlowNavigationDelegate
//    ) {
//        self.userWalletModel = userWalletModel
//        self.needAccessCodeValidation = needAccessCodeValidation
//        self.coordinator = coordinator
//        self.navigationDelegate = navigationDelegate
//    }
//
//    func buildSteps() -> [HotOnboardingFlowStep] {
//        var steps: [HotOnboardingFlowStep] = []
//
//        if needAccessCodeValidation {
//            steps.append(makeAccessCodeValidateStep())
//        }
//
//        steps.append(contentsOf: [makeAccessCodeCreateStep(), makeDoneStep()])
//
//        return steps
//    }
// }
//
//// MARK: - Steps maker
//
// private extension HotOnboardingAccessCodeChangeFlowBuilder {
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
//    func makeAccessCodeCreateStep() -> HotOnboardingFlowStep {
//        let skipAction = HotOnboardingFlowNavigation.Action { [weak self] in
//            self?.coordinator?.openAccesCodeSkipAlert(
//                onAllow: {
//                    self?.goNextStep()
//                }
//            )
//        }
//
//        let navigation = HotOnboardingFlowNavigation(
//            title: Localization.accessCodeNavtitle,
//            leadingItem: nil,
//            trailingItem: .skip(skipAction)
//        )
//
//        let viewModel = HotOnboardingAccessCodeCreateViewModel(delegate: self)
//        let content = { HotOnboardingAccessCodeCreateView(viewModel: viewModel) }
//
//        let backAction = HotOnboardingFlowNavigation.Action {
//            viewModel.resetState()
//        }
//
//        viewModel.$state
//            .sink { [weak navigationDelegate] accessCodeState in
//                switch accessCodeState {
//                case .accessCode:
//                    navigationDelegate?.leadingItemChanged(to: nil)
//                case .confirmAccessCode:
//                    navigationDelegate?.leadingItemChanged(to: .back(backAction))
//                }
//            }
//            .store(in: &bag)
//
//        return HotOnboardingFlowStep(navigation: navigation, content: content)
//    }
//
//    func changeAccessCodeNavigationTrailingItem(state: HotOnboardingAccessCodeCreateViewModel.State) {
//        switch state {
//        case .accessCode:
//            navigationDelegate?.leadingItemChanged(to: nil)
//        case .confirmAccessCode:
//            let action = HotOnboardingFlowNavigation.Action {}
//            navigationDelegate?.leadingItemChanged(to: .back(action))
//        }
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
//            type: .walletReady,
//            onAppear: {},
//            onComplete: weakify(self, forFunction: HotOnboardingAccessCodeChangeFlowBuilder.closeOnboarding)
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
// private extension HotOnboardingAccessCodeChangeFlowBuilder {
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
// extension HotOnboardingAccessCodeChangeFlowBuilder: CommonHotAccessCodeManagerDelegate {
//    func handleAccessCodeSuccessful(userWalletModel: UserWalletModel) {
//        goNextStep()
//    }
//
//    func handleAccessCodeDelete(userWalletModel: UserWalletModel) {
//        // [REDACTED_TODO_COMMENT]
//    }
// }
//
//// MARK: - HotOnboardingAccessCodeDelegate
//
// extension HotOnboardingAccessCodeChangeFlowBuilder: HotOnboardingAccessCodeCreateDelegate {
//    func isRequestBiometricsNeeded() -> Bool {
//        false
//    }
//
//    func accessCodeComplete(accessCode: String) {
//        // [REDACTED_TODO_COMMENT]
//        goNextStep()
//    }
// }
