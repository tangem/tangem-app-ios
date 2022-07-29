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
    @Published var cardOperationViewModel: CardOperationViewModel?

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
    func openChangeAccessCodeWarningView(action: @escaping (@escaping (Result<Void, Error>) -> Void) -> Void) {
        cardOperationViewModel = CardOperationViewModel(title: "details_manage_security_access_code".localized,
                                                        buttonTitle: "common_continue",
                                                        alert: "Пароль будет изменен только на данной карте, для изменения пароля на остальных картах необходимо будет выполнить функцию синхронизации карт.",
                                                        actionButtonPressed: action,
                                                        coordinator: self)
    }

    func openSecurityMode(cardModel: CardViewModel) {
        let coordinator = SecurityModeCoordinator(popToRootAction: popToRootAction)
        let options = SecurityModeCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        securityManagementCoordinator = coordinator
    }
}

// MARK: - CardOperationRoutable

extension CardSettingsCoordinator: CardOperationRoutable {
    func dismissCardOperation() {
        cardOperationViewModel = nil
    }
}
