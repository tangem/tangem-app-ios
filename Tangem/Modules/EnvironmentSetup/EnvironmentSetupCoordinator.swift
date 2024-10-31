//
//  EnvironmentSetupCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class EnvironmentSetupCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: EnvironmentSetupViewModel?

    // MARK: - Child view models

    @Published var supportedBlockchainsPreferencesViewModel: SupportedBlockchainsPreferencesViewModel?
    @Published var stakingBlockchainsPreferencesViewModel: SupportedBlockchainsPreferencesViewModel?

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
            blockchainIds: SupportedBlockchains.testableIDs.map { .init(name: $0, id: $0) }.toSet(),
            featureStorageKeyPath: \.supportedBlockchainsIds
        )
    }

    func openStakingBlockchainsPreferences() {
        stakingBlockchainsPreferencesViewModel = SupportedBlockchainsPreferencesViewModel(
            blockchainIds: StakingFeatureProvider.testableBlockchainItems.map { .init(name: $0.name, id: $0.id) }.toSet(),
            featureStorageKeyPath: \.stakingBlockchainsIds
        )
    }
}
