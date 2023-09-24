//
//  ManageTokensNetworkSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class ManageTokensNetworkSelectorCoordinator: CoordinatorObject {
    var dismissAction: Action<Void>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Published

    @Published private(set) var manageTokensNetworkSelectorViewModel: ManageTokensNetworkSelectorViewModel? = nil

    // MARK: - Child ViewModels

    @Published var addCustomTokenViewModel: LegacyAddCustomTokenViewModel? = nil

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    // MARK: - Implmentation

    func start(with options: Options) {
        manageTokensNetworkSelectorViewModel = .init(tokenItems: options.tokenItems, coordinator: self)
    }
}

extension ManageTokensNetworkSelectorCoordinator {
    struct Options {
        let tokenItems: [TokenItem]
    }
}

extension ManageTokensNetworkSelectorCoordinator: ManageTokensNetworkSelectorRoutable {
    func openAddCustomTokenModule() {}

    func closeModule() {
        dismiss()
    }
}
