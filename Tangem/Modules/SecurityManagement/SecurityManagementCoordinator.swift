//
//  SecurityManagementCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class SecurityManagementCoordinator: CoordinatorObject {
    var dismissAction: () -> Void = {}
    var popToRootAction: (PopToRootOptions) -> Void = { _ in }
    
    //MARK: - Main view model
    @Published private(set) var secManagementViewModel: SecurityManagementViewModel? = nil
    
    //MARK: - Child view models
    @Published var cardOperationViewModel: CardOperationViewModel? = nil
    
    //MARK: - Private helpers
    @Published var emptyModel: Int? = nil //Fix single navigation link issue
    
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
                                                        alert: "details_row_title_reset_factory_settings_warning".localized,
                                                        actionButtonPressed: action,
                                                        coordinator: self)
    }
}

extension SecurityManagementCoordinator: CardOperationRoutable {}
