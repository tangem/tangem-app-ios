//
//  EnvironmentSetupCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemNFT

class EnvironmentSetupCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: EnvironmentSetupViewModel?

    // MARK: - Child view models

    @Published var supportedBlockchainsPreferencesViewModel: SupportedBlockchainsPreferencesViewModel?
    @Published var addressesInfoViewModel: AddressesInfoViewModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(coordinator: self)
    }
}

// MARK: - Options

extension EnvironmentSetupCoordinator {
    struct Options {}
}

// MARK: - EnvironmentSetupRoutable

extension EnvironmentSetupCoordinator: EnvironmentSetupRoutable {
    func openSupportedBlockchainsPreferences() {
        supportedBlockchainsPreferencesViewModel = SupportedBlockchainsPreferencesViewModel(
            blockchainIds: SupportedBlockchains.testableBlockchains(version: .v2).map { .init(name: $0.displayName, id: $0.networkId) }.toSet(),
            featureStorageKeyPath: \.supportedBlockchainsIds
        )
    }

    func openStakingBlockchainsPreferences() {
        supportedBlockchainsPreferencesViewModel = SupportedBlockchainsPreferencesViewModel(
            blockchainIds: StakingFeatureProvider.testableBlockchainItems.map { .init(name: $0.name, id: $0.id) }.toSet(),
            featureStorageKeyPath: \.stakingBlockchainsIds
        )
    }

    func openNFTBlockchainsPreferences() {
        let isTestnet = AppEnvironment.current.isTestnet
        let allNFTChains = NFTChain.allCases(isTestnet: isTestnet)

        supportedBlockchainsPreferencesViewModel = SupportedBlockchainsPreferencesViewModel(
            blockchainIds: allNFTChains.map { .init(name: $0.id, id: $0.id) }.toSet(),
            featureStorageKeyPath: \.testableNFTChainsIds
        )
    }

    func openAddressesInfo() {
        addressesInfoViewModel = AddressesInfoViewModel()
    }
}
