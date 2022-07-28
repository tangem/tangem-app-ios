//
//  CardSettingsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class CardSettingsCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var сardSettingsViewModel: CardSettingsViewModel?

    // MARK: - Child view models

    @Published var attentionViewModel: AttentionViewModel?

    // MARK: - Child coordinators

    @Published var securityManagementCoordinator: SecurityModeCoordinator?

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        сardSettingsViewModel = CardSettingsViewModel(
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
    func openChangeAccessCode() {

    }

    func openSecurityMode(cardModel: CardViewModel) {
        let coordinator = SecurityModeCoordinator(popToRootAction: popToRootAction)
        let options = SecurityModeCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        securityManagementCoordinator = coordinator
    }

    func openTokenSynchronization() {

    }

    func openResetSavedCards() {

    }

    func openResetCardToFactoryWarning(mainButtonAction: @escaping () -> Void) {
        attentionViewModel = AttentionViewModel(
            isCheckedWarning: false,
            navigationTitle: "Reset to factory settings",
            title: "Attention",
            message: "This action will lead to the complete removal of the wallet from the selected card and it will not be possible to restore the current wallet on it or use the card to recover the password",
            warningText: "I understand that after performing this action, I will no longer have access to the current wallet",
            buttonTitle: "Reset the card",
            mainButtonAction: mainButtonAction
        )
    }
}
