//
//  CommonDynamicAddressesManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

final class CommonDynamicAddressesManager {
    private let tokenItem: TokenItem
    private let xpubAddressesWalletManagerProvider: XPUBAddressesWalletManagerProvider
    private let xpubKeyGenerator: XPUBKeyGenerator
    private let derivationModeUpdater: DerivationModeUpdater

    private let _state: CurrentValueSubject<DynamicAddressesState, Never>

    init(
        tokenItem: TokenItem,
        xpubAddressesWalletManagerProvider: XPUBAddressesWalletManagerProvider,
        xpubKeyGenerator: XPUBKeyGenerator,
        derivationModeUpdater: DerivationModeUpdater
    ) {
        self.tokenItem = tokenItem
        self.xpubAddressesWalletManagerProvider = xpubAddressesWalletManagerProvider
        self.xpubKeyGenerator = xpubKeyGenerator
        self.derivationModeUpdater = derivationModeUpdater

        let isEnabled = tokenItem.blockchainNetwork.derivationMode == .xpub
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
        if let (amount, destination) = try? xpubAddressesWalletManagerProvider.compoundTransactionIfNeeded() {
            return .compoundTransaction(amount, destination: destination)
        }

        return .none
    }

    func enableDynamicAddresses() async throws -> BlockchainNetwork {
        guard _state.value.isDisabled else {
            throw DynamicAddressesManagerError.attemptToEnableDynamicAddressesWhileAlreadyEnabled
        }

        let xpubKey = try await xpubKeyGenerator.generateXPUBKey()
        try Task.checkCancellation()

        try xpubAddressesWalletManagerProvider.updateToXpubKey(xpubKey: xpubKey)
        let updatedBlockchainNetwork = derivationModeUpdater.update(derivationMode: .xpub, for: tokenItem)

        _state.send(.enabled)
        return updatedBlockchainNetwork
    }

    func disableDynamicAddresses() throws -> BlockchainNetwork {
        guard _state.value.isEnabled else {
            throw DynamicAddressesManagerError.attemptToDisableDynamicAddressesWhileAlreadyDisabled
        }

        try xpubAddressesWalletManagerProvider.updateToPlainKey()
        let updatedBlockchainNetwork = derivationModeUpdater.update(derivationMode: .plain, for: tokenItem)

        _state.send(.disabled)
        return updatedBlockchainNetwork
    }
}
