//
//  WalletConnectResolveAvailableBlockchainsUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

final class WalletConnectResolveAvailableBlockchainsUseCase {
    func callAsFunction(
        connectionProposal: WalletConnectDAppConnectionProposal,
        selectedBlockchains: Set<Blockchain>,
        userWallet: some UserWalletModel
    ) -> WalletConnectDAppBlockchainsAvailabilityResult {
        let (availableRequiredBlockchains, unavailableRequiredBlockchains) = Self.resolveRequiredBlockchains(
            requiredBlockchains: connectionProposal.requiredBlockchains,
            userWallet: userWallet
        )

        let (availableOptionalBlockchains, unavailableOptionalBlockchains) = resolveOptionalBlockchains(
            optionalBlockchains: connectionProposal.optionalBlockchains,
            userWallet: userWallet
        )

        let resultAvailableRequiredBlockchains = availableRequiredBlockchains.map(\.toAvailableRequiredBlockchain)

        let resultAvailableOptionalBlockchains = availableOptionalBlockchains
            .subtracting(availableRequiredBlockchains)
            .map { optionalBlockchain in
                let isSelected = selectedBlockchains.contains(optionalBlockchain)
                return optionalBlockchain.toAvailableOptionalBlockchain(isSelected)
            }

        let sortedUnavailableRequiredBlockchains = unavailableRequiredBlockchains.sorted(by: \.displayName)

        let sortedAvailableBlockchains = (resultAvailableRequiredBlockchains + resultAvailableOptionalBlockchains)
            .sorted(by: \.blockchain.displayName)

        let sortedUnavailableBlockchains = unavailableOptionalBlockchains.sorted(by: \.displayName)

        return WalletConnectDAppBlockchainsAvailabilityResult(
            unavailableRequiredBlockchains: sortedUnavailableRequiredBlockchains,
            availableBlockchains: sortedAvailableBlockchains,
            notAddedBlockchains: sortedUnavailableBlockchains
        )
    }

    private static func resolveRequiredBlockchains(
        requiredBlockchains: Set<Blockchain>,
        userWallet: some UserWalletModel,
    ) -> (available: Set<Blockchain>, unavailable: Set<Blockchain>) {
        var available = Set<Blockchain>()
        var unavailable = Set<Blockchain>()

        guard !requiredBlockchains.isEmpty else {
            return (available: available, unavailable: unavailable)
        }

        for blockchain in requiredBlockchains {
            if userWallet.wcWalletModelProvider.getModels(with: blockchain.networkId).isEmpty {
                unavailable.insert(blockchain)
            } else {
                available.insert(blockchain)
            }
        }

        return (available: available, unavailable: unavailable)
    }

    private func resolveOptionalBlockchains(
        optionalBlockchains: Set<Blockchain>?,
        userWallet: some UserWalletModel,
    ) -> (available: Set<Blockchain>, unavailable: Set<Blockchain>) {
        var available = Set<Blockchain>()
        var unavailable = Set<Blockchain>()

        guard let optionalBlockchains, !optionalBlockchains.isEmpty else {
            return (available: available, unavailable: unavailable)
        }

        for blockchain in optionalBlockchains {
            if userWallet.wcWalletModelProvider.getModels(with: blockchain.networkId).isEmpty {
                unavailable.insert(blockchain)
            } else {
                available.insert(blockchain)
            }
        }

        return (available: available, unavailable: unavailable)
    }
}

private extension Blockchain {
    var toAvailableRequiredBlockchain: WalletConnectDAppBlockchainsAvailabilityResult.AvailableBlockchain {
        WalletConnectDAppBlockchainsAvailabilityResult.AvailableBlockchain.required(self)
    }

    func toAvailableOptionalBlockchain(_ isSelected: Bool) -> WalletConnectDAppBlockchainsAvailabilityResult.AvailableBlockchain {
        WalletConnectDAppBlockchainsAvailabilityResult.AvailableBlockchain.optional(.init(blockchain: self, isSelected: isSelected))
    }
}
