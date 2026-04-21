//
//  DynamicAddressesCustomDerivationChecker.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct TangemSdk.DerivationPath
import enum TangemSdk.DerivationNode

enum DynamicAddressesCustomDerivationChecker {
    static func canAddCustomToken(tokenItem: TokenItem, existingTokens: [TokenItem]) -> Bool {
        guard tokenItem.blockchain.isDynamicAddressesSupported else {
            return true
        }

        let existingTokensWithDynamicAddressesEnabled = existingTokens.filter {
            $0.blockchainNetwork.isDynamicAddressesEnabled()
        }

        let hasTokenWithDynamicAddressesEnabled = existingTokensWithDynamicAddressesEnabled.contains { existing in
            let lsh = existing.blockchainNetwork.derivationPath?.nodes.prefix(3)
            let rhs = tokenItem.blockchainNetwork.derivationPath?.nodes.prefix(3)
            return lsh == rhs
        }

        return !hasTokenWithDynamicAddressesEnabled
    }

    static func canEnableDynamicAddresses(for tokenItem: TokenItem, existingTokens: [TokenItem]) -> Bool {
        guard tokenItem.blockchain.isDynamicAddressesSupported else {
            return true
        }

        let anotherTokens = existingTokens.filter { $0 != tokenItem }

        let anotherTokensWithSameBlockchain = anotherTokens.filter {
            $0.blockchain == tokenItem.blockchain
        }

        let anotherTokensWithSameDerivationAccountLevel = anotherTokensWithSameBlockchain.filter { existing in
            let lsh = existing.blockchainNetwork.derivationPath?.nodes.prefix(3)
            let rhs = tokenItem.blockchainNetwork.derivationPath?.nodes.prefix(3)
            return lsh == rhs
        }

        return anotherTokensWithSameDerivationAccountLevel.isEmpty
    }
}
