//
//  LockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript
}

extension LockingScriptBuilder {
    func lockingScript(for address: any Address) throws -> UTXOLockingScript {
        switch address {
        case let address as LockingScriptAddress:
            return address.lockingScript
        case let address:
            return try lockingScript(for: address.value)
        }
    }
}

enum LockingScriptBuilderError: LocalizedError {
    case wrongAddress
    case wrongBech32Prefix
    case wrongChecksum
    case unsupportedVersion
    case unsupportedScriptType
    case lockingScriptNotFound
}

// MARK: - MultiLockingScriptBuilder

extension LockingScriptBuilder where Self == MultiLockingScriptBuilder {
    static func bitcoin(isTestnet: Bool) -> Self {
        let network: UTXONetworkParams = isTestnet ? BitcoinTestnetNetworkParams() : BitcoinNetworkParams()
        return MultiLockingScriptBuilder(decoders: [
            TaprootLockingScriptBuilder(network: network),
            SegWitLockingScriptBuilder(network: network),
            Base58LockingScriptBuilder(network: network),
        ])
    }

    static func litecoin() -> Self {
        let network: UTXONetworkParams = LitecoinNetworkParams()
        return MultiLockingScriptBuilder(decoders: [SegWitLockingScriptBuilder(network: network), Base58LockingScriptBuilder(network: network)])
    }

    static func bitcoinCash(isTestnet: Bool) -> Self {
        let network: UTXONetworkParams = isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams()
        return MultiLockingScriptBuilder(decoders: [CashAddrLockingScriptBuilder(network: network), Base58LockingScriptBuilder(network: network)])
    }
}

// MARK: - Base58LockingScriptBuilder

extension LockingScriptBuilder where Self == Base58LockingScriptBuilder {
    static func dogecoin() -> Self {
        return Base58LockingScriptBuilder(network: DogecoinNetworkParams())
    }

    static func dash(isTestnet: Bool) -> Self {
        return Base58LockingScriptBuilder(network: isTestnet ? DashTestNetworkParams() : DashMainNetworkParams())
    }

    static func ravencoin(isTestnet: Bool) -> Self {
        return Base58LockingScriptBuilder(network: isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams())
    }

    static func ducatus() -> Self {
        return Base58LockingScriptBuilder(network: DucatusNetworkParams())
    }

    static func clore() -> Self {
        return Base58LockingScriptBuilder(network: CloreMainNetworkParams())
    }

    static func radiant() -> Self {
        return Base58LockingScriptBuilder(network: RadiantNetworkParams())
    }

    static func pepecoin(isTestnet: Bool) -> Self {
        return Base58LockingScriptBuilder(network: isTestnet ? PepecoinTestnetNetworkParams() : PepecoinMainnetNetworkParams())
    }
}

// MARK: - KaspaAddressLockingScriptBuilder

extension LockingScriptBuilder where Self == KaspaAddressLockingScriptBuilder {
    static func kaspa() -> Self {
        return KaspaAddressLockingScriptBuilder(network: KaspaNetworkParams())
    }
}

// MARK: - SegWitLockingScriptBuilder

extension LockingScriptBuilder where Self == SegWitLockingScriptBuilder {
    static func fact0rn() -> Self {
        return SegWitLockingScriptBuilder(network: Fact0rnMainNetworkParams())
    }
}
