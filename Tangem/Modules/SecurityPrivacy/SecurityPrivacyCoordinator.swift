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
    // [REDACTED_TODO_COMMENT]
    
    // MARK: - Child coordinators
    @Published var securityManagementCoordinator: SecurityManagementCoordinator?
    
    required init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }
    
    func start(with options: Options) {
        switch options {
        case let .cardModel(viewModel):
            securityPrivacyViewModel = SecurityPrivacyViewModel(cardModel: viewModel, coordinator: self)
        }
    }
}

extension SecurityPrivacyCoordinator {
    enum Options {
        case cardModel(CardViewModel)
    }
}

// MARK: - SecurityPrivacyRoutable

extension SecurityPrivacyCoordinator: SecurityPrivacyRoutable {
    func openChangeAccessCode() {
        
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
