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

        let siblings = existingTokens.filter {
            $0.blockchain == tokenItem.blockchain && $0.blockchainNetwork.isDynamicAddressesEnabled()
        }

        return !siblings.contains { pathsCouldCollide(tokenItem, $0) }
    }

    static func canEnableDynamicAddresses(for tokenItem: TokenItem, existingTokens: [TokenItem]) -> Bool {
        guard tokenItem.blockchain.isDynamicAddressesSupported else {
            return true
        }

        let siblings = existingTokens.filter {
            $0 != tokenItem && $0.blockchain == tokenItem.blockchain
        }

        return !siblings.contains { pathsCouldCollide(tokenItem, $0) }
    }

    /// A collision is possible only when both paths have the standard BIP-44 length and share
    /// the same account prefix. Missing paths or non-standard lengths cannot collide with
    /// XPUB-derived addresses, so the operation is allowed.
    private static func pathsCouldCollide(_ lhs: TokenItem, _ rhs: TokenItem) -> Bool {
        guard
            let lhsNodes = lhs.blockchainNetwork.derivationPath?.nodes,
            let rhsNodes = rhs.blockchainNetwork.derivationPath?.nodes,
            lhsNodes.count == Constants.bip44PathLength,
            rhsNodes.count == Constants.bip44PathLength
        else {
            return false
        }

        return lhsNodes.prefix(Constants.accountPrefixLength) == rhsNodes.prefix(Constants.accountPrefixLength)
    }
}

extension DynamicAddressesCustomDerivationChecker {
    enum Constants {
        /// Standard BIP-44 path: `m / purpose' / coin_type' / account' / change / address_index`.
        /// XPUB-based Dynamic Addresses derive addresses at exactly this depth, so paths of any
        /// other length cannot share an address with them.
        static let bip44PathLength = 5

        /// Leading nodes that identify the BIP-44 `purpose / coin_type / account` triple — the scope of the XPUB.
        static let accountPrefixLength = 3
    }
}
