//
//  CommonDynamicAddressesManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class CommonDynamicAddressesManager {
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
        _state = .init(isEnabled ? .enabled : .disabled)
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

    var enablingRequirements: DynamicAddressesEnablingRequirements? {
        if xpubKeyGenerator.derivationIsNeeded() {
            return .xpubDerivationIsNeeded
        }

        return .none
    }

    var disablingRequirements: DynamicAddressesDisablingRequirements? {
        if let (amount, destination) = try? dynamicAddressesWalletUpdater.compoundTransactionIfNeeded() {
            return .compoundTransaction(amount, destination: destination)
        }

        return .none
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

    func disableDynamicAddresses() throws {
        guard _state.value.isEnabled else {
            throw DynamicAddressesManagerError.attemptToDisableDynamicAddressesWhileAlreadyDisabled
        }

        try dynamicAddressesWalletUpdater.updateToPlainKey()

        let updatedBlockchainNetwork = BlockchainNetwork(
            tokenItem.blockchain,
            derivationPath: tokenItem.blockchainNetwork.derivationPath,
            derivationLevel: .plain
        )
        derivationLevelUpdater.update(blockchainNetwork: updatedBlockchainNetwork, for: tokenItem)

        _state.send(.disabled)
    }
}
