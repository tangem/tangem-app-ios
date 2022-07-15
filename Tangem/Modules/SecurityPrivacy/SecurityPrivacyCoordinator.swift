//
//  SecurityPrivacyCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class SecurityPrivacyCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model
    @Published private(set) var securityPrivacyViewModel: SecurityPrivacyViewModel?

    // MARK: - Child view models
    @Published var cardOperationViewModel: CardOperationViewModel?

    // MARK: - Child coordinators
    @Published var securityManagementCoordinator: SecurityManagementCoordinator?

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        securityPrivacyViewModel = SecurityPrivacyViewModel(
            cardModel: options.cardModel,
            coordinator: self
        )
    }
}

extension SecurityPrivacyCoordinator {
    struct Options {
        let cardModel: CardViewModel
    }
}

// MARK: - SecurityPrivacyRoutable

extension SecurityPrivacyCoordinator: SecurityPrivacyRoutable {
    func openChangeAccessCodeWarningView(action: @escaping (@escaping (Result<Void, Error>) -> Void) -> Void) {
        cardOperationViewModel = CardOperationViewModel(title: "details_manage_security_access_code".localized,
                                                        buttonTitle: "common_continue",
                                                        alert: "Пароль будет изменен только на данной карте, для изменения пароля на остальных картах необходимо будет выполнить функцию синхронизации карт.",
                                                        actionButtonPressed: action,
                                                        coordinator: self)
    }

    func openChangeAccessCode(cardModel: CardViewModel) {
        cardModel.changeSecOption(.accessCode) { _ in }
    }

    func openSecurityManagement(cardModel: CardViewModel) {
        let coordinator = SecurityManagementCoordinator(popToRootAction: popToRootAction)
        let options = SecurityManagementCoordinator.Options(cardModel: cardModel)
        coordinator.start(with: options)
        securityManagementCoordinator = coordinator
    }

    func openTokenSynchronization() {

    }

    func openResetSavedCards() {

    }
}

// MARK: - CardOperationRoutable

extension SecurityPrivacyCoordinator: CardOperationRoutable {
    func dismissCardOperation() {
        cardOperationViewModel = nil
    }
}
