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

    // MARK: - Child view models

    @Published var networkSelectorModel: AddCustomTokenNetworksListViewModel?
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
        let userWalletConfig = options.userWalletConfig

        let supportedBlockchains = Array(userWalletConfig.supportedBlockchains)
            .filter { $0.curve.supportsDerivation }
            .sorted(by: \.displayName)

        let settings = AddCustomTokenViewModel.ManageTokensSettings(
            supportedBlockchains: supportedBlockchains,
            hdWalletsSupported: userWalletConfig.hasFeature(.hdWallets),
            derivationStyle: userWalletConfig.derivationStyle,
            analyticsSourceRawValue: options.analyticsSourceRawValue
        )

        rootViewModel = AddCustomTokenViewModel(
            settings: settings,
            userTokensManager: options.userTokensManager,
            coordinator: self
        )
    }
}

// MARK: - Options

extension AddCustomTokenCoordinator {
    struct Options {
        let userWalletConfig: UserWalletConfig
        let userTokensManager: UserTokensManager
        let analyticsSourceRawValue: String
    }
}

// MARK: - AddCustomTokenRoutable

extension AddCustomTokenCoordinator: AddCustomTokenRoutable, WalletSelectorRoutable {
    func openWalletSelector(with dataSource: WalletSelectorDataSource) {
        let walletSelectorViewModel = WalletSelectorViewModel(dataSource: dataSource, coordinator: self)
        self.walletSelectorViewModel = walletSelectorViewModel
    }

    func closeWalletSelector() {
        walletSelectorViewModel = nil
    }

    func openNetworkSelector(selectedBlockchainNetworkId: String?, blockchains: [Blockchain]) {
        let networkSelectorModel = AddCustomTokenNetworksListViewModel(
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

    func dissmisWalletSelectorModule() {
        walletSelectorViewModel = nil
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
