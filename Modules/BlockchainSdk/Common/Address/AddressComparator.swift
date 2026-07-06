//
//  AddressComparator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Compare addresses across different blockchain networks applying chain-specific rules.
/// Validates case-sensitive/case-insensitive rules for specific cases.
public struct AddressComparator {
    public init() {}

    public func addressesMatch(_ lhs: String, _ rhs: String, blockchain: Blockchain) -> Bool {
        let lhs = lhs.trimmingCharacters(in: .whitespacesAndNewlines)
        let rhs = rhs.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !lhs.isEmpty, !rhs.isEmpty else {
            return false
        }

        if lhs == rhs {
            return true
        }

        if blockchain.isEvm {
            return lhs.isEvmAddress
                && rhs.isEvmAddress
                && lhs.lowercased() == rhs.lowercased()
        }

        if let lockingScriptBuilder = lockingScriptBuilder(for: blockchain) {
            return lockingScriptsMatch(lhs, rhs, using: lockingScriptBuilder)
        }

        return false
    }
}

private extension AddressComparator {
    func lockingScriptBuilder(for blockchain: Blockchain) -> (any LockingScriptBuilder)? {
        let isTestnet = blockchain.isTestnet

        switch blockchain {
        case .bitcoin:
            return MultiLockingScriptBuilder.bitcoin(isTestnet: isTestnet)
        case .bitcoinCash:
            return MultiLockingScriptBuilder.bitcoinCash(isTestnet: isTestnet)
        case .litecoin:
            return MultiLockingScriptBuilder.litecoin()
        case .dogecoin:
            return Base58LockingScriptBuilder.dogecoin()
        case .dash:
            return Base58LockingScriptBuilder.dash(isTestnet: isTestnet)
        case .ravencoin:
            return Base58LockingScriptBuilder.ravencoin(isTestnet: isTestnet)
        case .ducatus:
            return Base58LockingScriptBuilder.ducatus()
        case .kaspa:
            let network: UTXONetworkParams = isTestnet ? KaspaTestNetworkParams() : KaspaNetworkParams()
            return KaspaAddressLockingScriptBuilder(network: network)
        case .radiant:
            return Base58LockingScriptBuilder.radiant()
        case .koinos:
            let network: UTXONetworkParams = isTestnet ? BitcoinTestnetNetworkParams() : BitcoinNetworkParams()
            return Base58LockingScriptBuilder(network: network)
        case .clore:
            return Base58LockingScriptBuilder.clore()
        case .fact0rn:
            return SegWitLockingScriptBuilder.fact0rn()
        case .pepecoin:
            return Base58LockingScriptBuilder.pepecoin(isTestnet: isTestnet)
        default:
            return nil
        }
    }

    /// Compare addresses by their locking scripts and data that already include case-insensitive/case-sensitive rules
    /// for specific cases.
    /// For example, Bitcoin Bech32 addresses are case-insensitive, but Bitcoin Legacy addresses are case-sensitive.
    func lockingScriptsMatch(
        _ lhs: String,
        _ rhs: String,
        using lockingScriptBuilder: any LockingScriptBuilder
    ) -> Bool {
        guard
            let lhsScript = try? lockingScriptBuilder.lockingScript(for: lhs),
            let rhsScript = try? lockingScriptBuilder.lockingScript(for: rhs)
        else {
            return false
        }

        return lhsScript.type == rhsScript.type && lhsScript.data == rhsScript.data
    }
}
