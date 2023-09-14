//
//  ManageTokensCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class ManageTokensCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    func start(with options: ManageTokensCoordinator.Options) {}

    // MARK: - Published

    @Published private(set) var manageTokensViewModel: ManageTokensViewModel? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }
}

extension ManageTokensCoordinator {
    struct Options {}
}

extension ManageTokensCoordinator: ManageTokensRoutable {
    func close() {}
    func openAddCustom() {}
}
