////
////  HotOnboardingWalletImportFlowBuilder.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2025 Tangem AG. All rights reserved.
////
//
// import Foundation
// import Combine
// import TangemLocalization
// import struct TangemSdk.Mnemonic
//
// final class HotOnboardingWalletImportFlowBuilder: HotOnboardingFlowBuilder {
//    let hasProgressBar = true
//
//    [REDACTED_USERNAME](\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor
//
//    private var userWalletModel: UserWalletModel?
//
//    private weak var coordinator: HotOnboardingFlowRoutable?
//    private weak var navigationDelegate: HotOnboardingFlowNavigationDelegate?
//
//    private var bag: Set<AnyCancellable> = []
//
//    init(coordinator: HotOnboardingFlowRoutable, navigationDelegate: HotOnboardingFlowNavigationDelegate) {
//        self.coordinator = coordinator
//        self.navigationDelegate = navigationDelegate
//    }
//
//    func buildSteps() -> [HotOnboardingFlowStep] {
//        var steps = [makeSeedPhraseImportStep(), makeImportCompletedStep(), makeAccessCodeCreateStep()]
//
//        let factory = PushNotificationsHelpersFactory()
//        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)
//
//        if availabilityProvider.isAvailable {
//            steps.append(makePushNotificationsStep())
//        }
//
//        steps.append(makeDoneStep())
//
//        return steps
//    }
// }
//
//// MARK: - Steps maker
//
// private extension HotOnboardingWalletImportFlowBuilder {
//    func makeSeedPhraseImportStep() -> HotOnboardingFlowStep {
//        let closeAction = HotOnboardingFlowNavigation.Action(
//            closure: weakify(self, forFunction: HotOnboardingWalletImportFlowBuilder.closeOnboarding)
//        )
//
//        let navigation = HotOnboardingFlowNavigation(
//            title: Localization.walletImportSeedNavtitle,
//            leadingItem: .back(closeAction),
//            trailingItem: nil
//        )
//
//        let viewModel = OnboardingSeedPhraseImportViewModel(
//            inputProcessor: SeedPhraseInputProcessor(),
//            delegate: self
//        )
//
//        let content = { OnboardingSeedPhraseImportView(viewModel: viewModel) }
//
//        return HotOnboardingFlowStep(navigation: navigation, content: content)
//    }
//
//    func makeImportCompletedStep() -> HotOnboardingFlowStep {
//        let navigation = HotOnboardingFlowNavigation(
//            title: Localization.walletImportSuccessNavtitle,
//            leadingItem: nil,
//            trailingItem: nil
//        )
//
//        let viewModel = HotOnboardingSuccessViewModel(
//            type: .walletImported,
//            onAppear: {},
//            onComplete: weakify(self, forFunction: HotOnboardingWalletImportFlowBuilder.goNextStep)
//        )
//
//        let content = { HotOnboardingSuccessView(viewModel: viewModel) }
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
//    func makePushNotificationsStep() -> HotOnboardingFlowStep {
//        let navigation = HotOnboardingFlowNavigation(
//            title: Localization.onboardingTitleNotifications,
//            leadingItem: nil,
//            trailingItem: nil
//        )
//
//        let factory = PushNotificationsHelpersFactory()
//        let permissionManager = factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)
//
//        let viewModel = PushNotificationsPermissionRequestViewModel(
//            permissionManager: permissionManager,
//            delegate: self
//        )
//
//        let content = {
//            PushNotificationsPermissionRequestView(
//                viewModel: viewModel,
//                topInset: 0,
//                buttonsAxis: .vertical
//            )
//        }
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
//            type: .walletReady,
//            onAppear: weakify(self, forFunction: HotOnboardingWalletImportFlowBuilder.openConfetti),
//            onComplete: weakify(self, forFunction: HotOnboardingWalletImportFlowBuilder.openMain)
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
// private extension HotOnboardingWalletImportFlowBuilder {
//    func goNextStep() {
//        coordinator?.goNextStep()
//    }
//
//    func openMain() {
//        guard let userWalletModel else {
//            return
//        }
//        coordinator?.openMain(userWalletModel: userWalletModel)
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
//// MARK: - SeedPhraseImportDelegate
//
// extension HotOnboardingWalletImportFlowBuilder: SeedPhraseImportDelegate {
//    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String?) {
//        // [REDACTED_TODO_COMMENT]
//        // self.userWalletModel = userWalletModel
//        goNextStep()
//    }
// }
//
//// MARK: - HotOnboardingAccessCodeDelegate
//
// extension HotOnboardingWalletImportFlowBuilder: HotOnboardingAccessCodeCreateDelegate {
//    func isRequestBiometricsNeeded() -> Bool {
//        true
//    }
//
//    func accessCodeComplete(accessCode: String) {
//        guard let userWalletModel else {
//            return
//        }
//        // [REDACTED_TODO_COMMENT]
//        goNextStep()
//    }
// }
//
//// MARK: - PushNotificationsPermissionRequestDelegate
//
// extension HotOnboardingWalletImportFlowBuilder: PushNotificationsPermissionRequestDelegate {
//    func didFinishPushNotificationOnboarding() {
//        goNextStep()
//    }
// }
