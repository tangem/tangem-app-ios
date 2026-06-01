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
    private(set) var tokenItem: TokenItem

    private let xpubAddressesWalletManagerProvider: XPUBAddressesWalletManagerProvider
    private let xpubAddressesBalancesChecker: XPUBAddressesBalancesChecker
    private let xpubKeyGenerator: XPUBKeyGenerator
    private let blockchainSettingsUpdater: BlockchainSettingsUpdater
    private let userTokensManager: UserTokensManager

    private let _otherBalancesState: CurrentValueSubject<OtherBalancesCheckState, Never>

    init(
        tokenItem: TokenItem,
        xpubAddressesWalletManagerProvider: XPUBAddressesWalletManagerProvider,
        xpubAddressesBalancesChecker: XPUBAddressesBalancesChecker,
        xpubKeyGenerator: XPUBKeyGenerator,
        blockchainSettingsUpdater: BlockchainSettingsUpdater,
        userTokensManager: UserTokensManager
    ) {
        self.tokenItem = tokenItem
        self.xpubAddressesWalletManagerProvider = xpubAddressesWalletManagerProvider
        self.xpubAddressesBalancesChecker = xpubAddressesBalancesChecker
        self.xpubKeyGenerator = xpubKeyGenerator
        self.blockchainSettingsUpdater = blockchainSettingsUpdater
        self.userTokensManager = userTokensManager

        // If DA is already enabled, no point in suggesting it — start in `.checkNotRequired`
        let isEnabled = tokenItem.blockchainNetwork.isDynamicAddressesEnabled()
        _otherBalancesState = .init(isEnabled ? .checkNotRequired : .checkRequired)
    }
}

// MARK: - DynamicAddressesManager

extension CommonDynamicAddressesManager: DynamicAddressesManager {
    var enablingRequirements: DynamicAddressesEnablingRequirements? {
        let canEnable = DynamicAddressesCustomDerivationChecker.canEnableDynamicAddresses(
            for: tokenItem,
            existingTokens: userTokensManager.userTokens
        )
        if !canEnable {
            return .customTokensRemoveIsNeeded
        }

        if xpubKeyGenerator.derivationIsNeeded() {
            return .xpubDerivationIsNeeded
        }

        return .none
    }

    var disablingRequirements: DynamicAddressesDisablingRequirements? {
        if let (amount, destination) = xpubAddressesWalletManagerProvider.compoundTransactionIfNeeded() {
            return .compoundTransaction(amount, destination: destination)
        }

        return .none
    }

    @MainActor
    func hasDynamicAddressesBalancesFlag() async -> Bool {
        switch _otherBalancesState.value {
        case .checkNotRequired:
            return false

        case .checked(let hasBalances):
            return hasBalances

        // Pending unspent outputs (e.g. an unconfirmed compound tx broadcast in a previous
        // session, or any external broadcast) — suppress until they clear to avoid stale state
        case .checkRequired where xpubAddressesWalletManagerProvider.hasPendingUnspentOutputs:
            return false

        // XPUB derivation requires the user to tap the card; don't trigger it implicitly
        case .checkRequired where xpubKeyGenerator.derivationIsNeeded():
            return false

        case .checkRequired:
            do {
                let xpubKey = try await xpubKeyGenerator.generateXPUBKey()
                let report = try await xpubAddressesBalancesChecker.checkOtherAddressesBalances(xpubKey: xpubKey)
                _otherBalancesState.send(.checked(hasBalances: report.hasBalances))
                return report.hasBalances
            } catch {
                return false
            }
        }
    }

    @MainActor
    func enableDynamicAddresses() async throws -> BlockchainNetwork {
        guard !tokenItem.blockchainNetwork.isDynamicAddressesEnabled() else {
            throw DynamicAddressesManagerError.attemptToEnableDynamicAddressesWhileAlreadyEnabled
        }

        let xpubKey = try await xpubKeyGenerator.generateXPUBKey()
        try Task.checkCancellation()

        try xpubAddressesWalletManagerProvider.updateToXpubKey(xpubKey: xpubKey)
        let updatedBlockchainNetwork = blockchainSettingsUpdater.update(settings: .dynamicAddresses, for: tokenItem)

        tokenItem = tokenItem.with(blockchainNetwork: updatedBlockchainNetwork)
        // DA enabled — no need to suggest it
        _otherBalancesState.send(.checkNotRequired)
        return updatedBlockchainNetwork
    }

    @MainActor
    func disableDynamicAddresses() throws -> BlockchainNetwork {
        guard tokenItem.blockchainNetwork.isDynamicAddressesEnabled() else {
            throw DynamicAddressesManagerError.attemptToDisableDynamicAddressesWhileAlreadyDisabled
        }

        try xpubAddressesWalletManagerProvider.updateToPlainKey()
        let updatedBlockchainNetwork = blockchainSettingsUpdater.update(settings: nil, for: tokenItem)

        tokenItem = tokenItem.with(blockchainNetwork: updatedBlockchainNetwork)
        // After disable the compound transaction (if any) has just consolidated other-address balances
        // — suppress the flag until the next manager lifecycle to avoid a flicker before pending UTXO lands
        _otherBalancesState.send(.checkNotRequired)
        return updatedBlockchainNetwork
    }
}

// MARK: - OtherBalancesCheckState

private extension CommonDynamicAddressesManager {
    enum OtherBalancesCheckState {
        case checkRequired
        case checkNotRequired
        case checked(hasBalances: Bool)
    }
}
