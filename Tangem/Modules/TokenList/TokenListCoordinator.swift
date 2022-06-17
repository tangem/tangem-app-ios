//
//  TokenListCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class TokenListCoordinator: CoordinatorObject {
    var dismissAction: () -> Void = {}
    
    //MARK: - View models
    @Published var addCustomTokenViewModel: AddCustomTokenViewModel? = nil
    @Published private(set) var tokenListViewModel: TokenListViewModel!
    
    func start(with mode: TokenListViewModel.Mode) {
        tokenListViewModel = .init(mode: mode, coordinator: self)
    }
}

extension TokenListCoordinator: AddCustomTokenRoutable {
    func closeModule() {
        dismiss()
    }
}

extension TokenListCoordinator: TokenListRoutable {
    func openAddCustom() {
        addCustomTokenViewModel = .init(coordinator: self)
    }
}
