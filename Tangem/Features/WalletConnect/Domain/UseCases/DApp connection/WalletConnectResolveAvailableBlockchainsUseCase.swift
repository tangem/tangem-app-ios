//
//  WalletConnectResolveAvailableBlockchainsUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain
import TangemFoundation

final class WalletConnectResolveAvailableBlockchainsUseCase {
    // [REDACTED_TODO_COMMENT]
    func callAsFunction(
        sessionProposal: WalletConnectDAppSessionProposal,
        selectedBlockchains: some Sequence<Blockchain>,
        userWallet: some UserWalletModel
    ) -> WalletConnectDAppBlockchainsAvailabilityResult {
        let (availableRequiredBlockchains, unavailableRequiredBlockchains) = Self.resolveAvailableBlockchains(
            from: sessionProposal.requiredBlockchains,
            userWallet: userWallet
        )

        let (availableOptionalBlockchains, unavailableOptionalBlockchains) = Self.resolveAvailableBlockchains(
            from: sessionProposal.optionalBlockchains,
            userWallet: userWallet
        )

        let resultAvailableRequiredBlockchains = availableRequiredBlockchains.map(\.toAvailableRequiredBlockchain)

        let uniqueSelectedBlockchains = Set(selectedBlockchains)
        let resultAvailableOptionalBlockchains = availableOptionalBlockchains
            .subtracting(availableRequiredBlockchains)
            .map { optionalBlockchain in
                let isSelected = uniqueSelectedBlockchains.contains(optionalBlockchain)
                return optionalBlockchain.toAvailableOptionalBlockchain(isSelected)
            }

        let sortedUnavailableRequiredBlockchains = unavailableRequiredBlockchains.sorted(by: \.displayName)

        let sortedAvailableBlockchains = (resultAvailableRequiredBlockchains + resultAvailableOptionalBlockchains)
            .sorted(by: \.blockchain.displayName)

        let sortedUnavailableOptionalBlockchains = unavailableOptionalBlockchains
            .subtracting(unavailableRequiredBlockchains)
            .sorted(by: \.displayName)

        return WalletConnectDAppBlockchainsAvailabilityResult(
            unavailableRequiredBlockchains: sortedUnavailableRequiredBlockchains,
            availableBlockchains: sortedAvailableBlockchains,
            notAddedBlockchains: sortedUnavailableOptionalBlockchains
        )
    }

    // [REDACTED_TODO_COMMENT]
    private static func resolveAvailableBlockchains(
        from blockchains: Set<Blockchain>?,
        userWallet: some UserWalletModel,
    ) -> (available: Set<Blockchain>, unavailable: Set<Blockchain>) {
        var available = Set<Blockchain>()
        var unavailable = Set<Blockchain>()

        guard let blockchains, blockchains.isNotEmpty else {
            return (available: available, unavailable: unavailable)
        }

        for blockchain in blockchains {
            if userWallet.wcWalletModelProvider.getModels(with: blockchain.networkId).isEmpty {
                unavailable.insert(blockchain)
            } else {
                available.insert(blockchain)
            }
        }

        return (available: available, unavailable: unavailable)
    }

    func callAsFunction(
        sessionProposal: WalletConnectDAppSessionProposal,
        selectedBlockchains: some Sequence<Blockchain>,
        wcAccountsWalletModelProvider: some WalletConnectAccountsWalletModelProvider,
        account: (any CryptoAccountModel)?,
    ) -> WalletConnectDAppBlockchainsAvailabilityResult {
        let (availableRequiredBlockchains, unavailableRequiredBlockchains) = Self.resolveAvailableBlockchains(
            from: sessionProposal.requiredBlockchains,
            wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
            account: account
        )

        let (availableOptionalBlockchains, unavailableOptionalBlockchains) = Self.resolveAvailableBlockchains(
            from: sessionProposal.optionalBlockchains,
            wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
            account: account
        )

        let resultAvailableRequiredBlockchains = availableRequiredBlockchains.map(\.toAvailableRequiredBlockchain)

        let uniqueSelectedBlockchains = Set(selectedBlockchains)
        let resultAvailableOptionalBlockchains = availableOptionalBlockchains
            .subtracting(availableRequiredBlockchains)
            .map { optionalBlockchain in
                let isSelected = uniqueSelectedBlockchains.contains(optionalBlockchain)
                return optionalBlockchain.toAvailableOptionalBlockchain(isSelected)
            }

        let sortedUnavailableRequiredBlockchains = unavailableRequiredBlockchains.sorted(by: \.displayName)

        let sortedAvailableBlockchains = (resultAvailableRequiredBlockchains + resultAvailableOptionalBlockchains)
            .sorted(by: \.blockchain.displayName)

        let sortedUnavailableOptionalBlockchains = unavailableOptionalBlockchains
            .subtracting(unavailableRequiredBlockchains)
            .sorted(by: \.displayName)

        return WalletConnectDAppBlockchainsAvailabilityResult(
            unavailableRequiredBlockchains: sortedUnavailableRequiredBlockchains,
            availableBlockchains: sortedAvailableBlockchains,
            notAddedBlockchains: sortedUnavailableOptionalBlockchains
        )
    }

    private static func resolveAvailableBlockchains(
        from blockchains: Set<Blockchain>?,
        wcAccountsWalletModelProvider: some WalletConnectAccountsWalletModelProvider,
        account: (any CryptoAccountModel)?
    ) -> (available: Set<Blockchain>, unavailable: Set<Blockchain>) {
        var available = Set<Blockchain>()
        var unavailable = Set<Blockchain>()

        guard let blockchains, blockchains.isNotEmpty, let account else {
            return (available: available, unavailable: unavailable)
        }

        for blockchain in blockchains {
            let isUnavailableBlockchain = wcAccountsWalletModelProvider.getModels(
                with: blockchain.networkId,
                accountId: account.id.walletConnectIdentifierString
            ).isEmpty

            if isUnavailableBlockchain {
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
