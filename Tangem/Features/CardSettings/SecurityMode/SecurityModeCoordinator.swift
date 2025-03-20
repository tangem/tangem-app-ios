//
//  SecurityModeCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class SecurityModeCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Main view model

    @Published private(set) var securityModeViewModel: SecurityModeViewModel?

    // MARK: - Child view models

    @Published var cardOperationViewModel: CardOperationViewModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: SecurityModeCoordinator.Options) {
        securityModeViewModel = SecurityModeViewModel(securityOptionChangeInteractor: options.securityOptionChangeInteractor, coordinator: self)
    }
}

extension SecurityModeCoordinator {
    struct Options {
        let securityOptionChangeInteractor: SecurityOptionChanging
    }
}

extension SecurityModeCoordinator: SecurityModeRoutable {
    func openPinChange(with title: String, action: @escaping (@escaping (Result<Void, Error>) -> Void) -> Void) {
        cardOperationViewModel = CardOperationViewModel(
            title: title,
            buttonTitle: Localization.commonContinue,
            alert: Localization.detailsSecurityManagementWarning,
            actionButtonPressed: action,
            coordinator: self
        )
    }
}

extension SecurityModeCoordinator: CardOperationRoutable {
    func dismissCardOperation() {
        cardOperationViewModel = nil
    }
}
