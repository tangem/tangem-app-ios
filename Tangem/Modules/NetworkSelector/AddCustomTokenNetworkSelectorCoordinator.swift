//
//  AddCustomTokenNetworkSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

class AddCustomTokenNetworkSelectorCoordinator: CoordinatorObject {
    let output: AddCustomTokenNetworkSelectorCoordinatorOutput
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddCustomTokenNetworkSelectorViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        output: AddCustomTokenNetworkSelectorCoordinatorOutput,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.output = output
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = AddCustomTokenNetworkSelectorViewModel(
            selectedBlockchain: options.selectedBlockchain,
            blockchains: options.blockchains,
            coordinator: self
        )
    }
}

// MARK: - Options

extension AddCustomTokenNetworkSelectorCoordinator {
    struct Options {
        let selectedBlockchain: Blockchain
        let blockchains: [Blockchain]
    }
}

// MARK: - AddCustomTokenNetworkSelectorRoutable

extension AddCustomTokenNetworkSelectorCoordinator: AddCustomTokenNetworkSelectorRoutable {
    func didSelectNetwork(blockchain: Blockchain) {
        output.didSelectNetwork(blockchain: blockchain)
    }
}
