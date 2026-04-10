//
//  CommonDynamicAddressesManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

class CommonDynamicAddressesManager {
    private let tokenItem: TokenItem
    private let dynamicAddressesWalletUpdater: DynamicAddressesWalletUpdater
    private let xpubKeyGenerator: XPUBKeyGenerator
    private let derivationLevelUpdater: DerivationLevelUpdater

    private weak var walletModelUpdater: WalletModelUpdater?

    private let _state: CurrentValueSubject<DynamicAddressesState, Never>

    init(
        tokenItem: TokenItem,
        dynamicAddressesWalletUpdater: DynamicAddressesWalletUpdater,
        xpubKeyGenerator: XPUBKeyGenerator,
        derivationLevelUpdater: DerivationLevelUpdater
    ) {
        self.tokenItem = tokenItem
        self.dynamicAddressesWalletUpdater = dynamicAddressesWalletUpdater
        self.xpubKeyGenerator = xpubKeyGenerator
        self.derivationLevelUpdater = derivationLevelUpdater

        let isEnabled = tokenItem.blockchainNetwork.derivationLevel == .xpub
        let derivationIsNeeded = xpubKeyGenerator.derivationIsNeeded()

        _state = .init(
            isEnabled ? .enabled : .disabled(derivationIsNeeded: derivationIsNeeded)
        )
    }
}

// MARK: - DynamicAddressesManager

extension CommonDynamicAddressesManager: DynamicAddressesManager {
    var state: DynamicAddressesState {
        _state.value
    }

    var statePublisher: AnyPublisher<DynamicAddressesState, Never> {
        _state.eraseToAnyPublisher()
    }

    func configure(walletModelUpdater: any WalletModelUpdater) {
        self.walletModelUpdater = walletModelUpdater
    }

    func enableDynamicAddresses() async throws {
        guard _state.value.isDisabled else {
            throw DynamicAddressesManagerError.attemptToEnableDynamicAddressesWhileAlreadyEnabled
        }

        let xpubKey = try await xpubKeyGenerator.generateXPUBKey()
        try dynamicAddressesWalletUpdater.updateToXPUBKey(xpubKey: xpubKey)

        let updatedBlockchainNetwork = BlockchainNetwork(
            tokenItem.blockchain,
            derivationPath: tokenItem.blockchainNetwork.derivationPath,
            derivationLevel: .xpub
        )
        derivationLevelUpdater.update(blockchainNetwork: updatedBlockchainNetwork, for: tokenItem)
        walletModelUpdater?.startUpdateTask()

        _state.send(.enabled)
    }
}
