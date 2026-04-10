//
//  AddCustomTokenDerivationPathSelectorCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

class AddCustomTokenDerivationPathSelectorCoordinator: CoordinatorObject {
    let dismissAction: Action<AddCustomTokenDerivationOption?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddCustomTokenDerivationPathSelectorViewModel?

    // MARK: - Child view models

    @Published var derivationPathWriterViewModel: AddCustomTokenDerivationPathWriterViewModel?

    required init(
        dismissAction: @escaping Action<AddCustomTokenDerivationOption?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let rootViewModel = AddCustomTokenDerivationPathSelectorViewModel(
            selectedDerivationOption: options.selectedDerivationOption,
            defaultDerivationPath: options.defaultDerivationPath,
            blockchainDerivationOptions: options.blockchainDerivationOptions,
            context: options.context,
            blockchain: options.blockchain,
            coordinator: self
        )

        self.rootViewModel = rootViewModel
    }
}

// MARK: - Options

extension AddCustomTokenDerivationPathSelectorCoordinator {
    struct Options {
        let selectedDerivationOption: AddCustomTokenDerivationOption
        let defaultDerivationPath: DerivationPath
        let blockchainDerivationOptions: [AddCustomTokenDerivationOption]
        let context: ManageTokensContext
        let blockchain: Blockchain
    }
}

// MARK: - AddCustomTokenDerivationPathSelectorRoutable

extension AddCustomTokenDerivationPathSelectorCoordinator: AddCustomTokenDerivationPathSelectorRoutable {
    func didSelectOption(_ derivationOption: AddCustomTokenDerivationOption) {
        dismiss(with: derivationOption)
    }

    func openDerivationPathWriter(
        currentDerivationPath: String,
        context: ManageTokensContext,
        blockchain: Blockchain,
        output: AddCustomTokenDerivationPathWriterOutput
    ) {
        derivationPathWriterViewModel = AddCustomTokenDerivationPathWriterViewModel(
            currentDerivationPath: currentDerivationPath,
            context: context,
            blockchain: blockchain,
            output: output,
            coordinator: self
        )
    }
}

// MARK: - AddCustomTokenDerivationPathWriterRoutable

extension AddCustomTokenDerivationPathSelectorCoordinator: AddCustomTokenDerivationPathWriterRoutable {
    func closeDerivationPathWriter() {
        derivationPathWriterViewModel = nil
    }
}
