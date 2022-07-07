//
//  SecurityManagementCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class SecurityManagementCoordinator: CoordinatorObject {
    var dismissAction: Action
    var popToRootAction: ParamsAction<PopToRootOptions>

    // MARK: - Main view model
    @Published private(set) var secManagementViewModel: SecurityManagementViewModel? = nil

    // MARK: - Child view models
    @Published var cardOperationViewModel: CardOperationViewModel? = nil

    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: SecurityManagementCoordinator.Options) {
        secManagementViewModel = SecurityManagementViewModel(cardModel: options.cardModel, coordinator: self)
    }
}

extension SecurityManagementCoordinator {
    struct Options {
        let cardModel: CardViewModel
    }
}

extension SecurityManagementCoordinator: SecurityManagementRoutable {
    func openPinChange(with title: String, action: @escaping (@escaping (Result<Void, Error>) -> Void) -> Void) {
        cardOperationViewModel = CardOperationViewModel(title: title,
                                                        buttonTitle: "common_continue",
                                                        alert: "details_security_management_warning".localized,
                                                        actionButtonPressed: action,
                                                        coordinator: self)
    }
}

extension SecurityManagementCoordinator: CardOperationRoutable {
    func dismissCardOperation() {
        cardOperationViewModel = nil
    }
}
