//
//  AddCustomTokenCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk

class AddCustomTokenCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddCustomTokenViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    @Published var networkSelectorModel: AddCustomTokenNetworkSelectorViewModel?
    @Published var derivationSelectorModel: AddCustomTokenDerivationPathSelectorViewModel?
    @Published var walletSelectorViewModel: WalletSelectorViewModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = AddCustomTokenViewModel(settings: options.settings, userTokensManager: options.userTokensManager, coordinator: self)
    }
}

// MARK: - Options

extension AddCustomTokenCoordinator {
    struct Options {
        let settings: LegacyManageTokensSettings
        let userTokensManager: UserTokensManager
    }
}

// MARK: - AddCustomTokenRoutable

extension AddCustomTokenCoordinator: AddCustomTokenRoutable {
    func openWalletSelector(
        userWallets: [UserWallet],
        currentUserWalletId: Data?
    ) {
        let walletSelectorViewModel = WalletSelectorViewModel(userWallets: userWallets, currentUserWalletId: currentUserWalletId)
        walletSelectorViewModel.delegate = self
        self.walletSelectorViewModel = walletSelectorViewModel
    }

    func openNetworkSelector(selectedBlockchainNetworkId: String?, blockchains: [Blockchain]) {
        let networkSelectorModel = AddCustomTokenNetworkSelectorViewModel(
            selectedBlockchainNetworkId: selectedBlockchainNetworkId,
            blockchains: blockchains
        )
        networkSelectorModel.delegate = self
        self.networkSelectorModel = networkSelectorModel
    }

    func openDerivationSelector(selectedDerivationOption: AddCustomTokenDerivationOption, defaultDerivationPath: DerivationPath, blockchainDerivationOptions: [AddCustomTokenDerivationOption]) {
        let derivationSelectorModel = AddCustomTokenDerivationPathSelectorViewModel(
            selectedDerivationOption: selectedDerivationOption,
            defaultDerivationPath: defaultDerivationPath,
            blockchainDerivationOptions: blockchainDerivationOptions
        )
        derivationSelectorModel.delegate = self
        self.derivationSelectorModel = derivationSelectorModel
    }
}

extension AddCustomTokenCoordinator: WalletSelectorDelegate {
    func didSelectWallet(with userWalletId: Data) {
        walletSelectorViewModel = nil
        rootViewModel?.setSelectedWallet(userWalletId: userWalletId)
    }
}

extension AddCustomTokenCoordinator: AddCustomTokenNetworkSelectorDelegate {
    func didSelectNetwork(networkId: String) {
        networkSelectorModel = nil
        rootViewModel?.setSelectedNetwork(networkId: networkId)
    }
}

extension AddCustomTokenCoordinator: AddCustomTokenDerivationPathSelectorDelegate {
    func didSelectOption(_ derivationOption: AddCustomTokenDerivationOption) {
        derivationSelectorModel = nil
        rootViewModel?.setSelectedDerivationOption(derivationOption: derivationOption)
    }
}
