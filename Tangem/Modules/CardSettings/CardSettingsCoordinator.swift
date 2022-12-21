//
//  CardSettingsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class CardSettingsCoordinator: CoordinatorObject {
    let dismissAction: Action
    let popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var cardSettingsViewModel: CardSettingsViewModel?

    // MARK: - Child view models

    @Published var attentionViewModel: AttentionViewModel?

    // MARK: - Child coordinators

    @Published var securityManagementCoordinator: SecurityModeCoordinator?
    @Published var modalOnboardingCoordinator: OnboardingCoordinator?

    // MARK: - Helpers

    @Published var modalOnboardingCoordinatorKeeper: Bool = false

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        cardSettingsViewModel = CardSettingsViewModel(
            cardModel: options.cardModel,
            coordinator: self
        )
    }
}

extension CardSettingsCoordinator {
    struct Options {
        let cardModel: CardViewModel
    }
}

// MARK: - CardSettingsRoutable

extension CardSettingsCoordinator: CardSettingsRoutable {
    func openOnboarding(with input: OnboardingInput, hasOtherCards: Bool) {
        let dismissAction: Action = { [weak self] in
            self?.modalOnboardingCoordinator = nil
            self?.dismiss()
        }

        let coordinator = OnboardingCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        let options = OnboardingCoordinator.Options(input: input, destination: hasOtherCards ? .dismiss : .root)
        coordinator.start(with: options)
        modalOnboardingCoordinator = coordinator
    }

    func openSecurityMode(cardModel: CardViewModel) {
        let coordinator = SecurityModeCoordinator(popToRootAction: popToRootAction)
        let options = SecurityModeCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        securityManagementCoordinator = coordinator
    }

    func openResetCardToFactoryWarning(message: String, mainButtonAction: @escaping () -> Void) {
        Analytics.log(.buttonFactoryReset)
        attentionViewModel = AttentionViewModel(
            isWarningChecked: false,
            navigationTitle: L10n.cardSettingsResetCardToFactory,
            title: L10n.commonAttention,
            message: message,
            warningText: L10n.resetCardToFactoryWarningMessage,
            buttonTitle: L10n.resetCardToFactoryButtonTitle,
            mainButtonAction: mainButtonAction
        )
    }
}
