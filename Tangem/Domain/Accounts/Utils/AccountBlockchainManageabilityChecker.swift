//
//  AccountBlockchainManageabilityChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum AccountBlockchainManageabilityChecker {
    /// Checks if an account can manage a specific blockchain.
    /// Main accounts can manage any blockchain. Non-main accounts can only manage blockchains that support multiple accounts.
    static func canManageBlockchain(_ blockchain: Blockchain, for account: any CryptoAccountModel) -> Bool {
        isMainAccountOrSatisfiesPredicate(for: account) {
            AccountDerivationPathHelper(blockchain: blockchain).areAccountsAvailableForBlockchain()
        }
    }

    /// Checks if an account can manage a network by its networkId.
    /// Main accounts can manage any network. Non-main accounts can only manage networks that support multiple accounts.
    static func canManageNetwork(
        _ networkId: String,
        for account: any CryptoAccountModel,
        in supportedBlockchains: Set<Blockchain>
    ) -> Bool {
        isMainAccountOrSatisfiesPredicate(for: account) {
            blockchainSupportsAccounts(networkId: networkId, in: supportedBlockchains)
        }
    }
}

// MARK: - Private

private extension AccountBlockchainManageabilityChecker {
    /// Single entry point for "main account can do anything, non-main needs check" logic
    static func isMainAccountOrSatisfiesPredicate(
        for account: any CryptoAccountModel,
        predicate: () -> Bool
    ) -> Bool {
        guard !account.isMainAccount else { return true }
        return predicate()
    }

    /// Checks if a blockchain with the given networkId supports multiple accounts.
    static func blockchainSupportsAccounts(networkId: String, in supportedBlockchains: Set<Blockchain>) -> Bool {
        guard let blockchain = supportedBlockchains[networkId] else {
            return false
        }
        return AccountDerivationPathHelper(blockchain: blockchain).areAccountsAvailableForBlockchain()
    }
}
