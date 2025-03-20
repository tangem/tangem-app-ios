//
//  LockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import WalletCore
import BitcoinCore

protocol LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript
}

enum LockingScriptBuilderError: LocalizedError {
    case wrongAddress
    case bech32Prefix
    case unsupportedVersion
    case lockingScriptNotFound
}

// MARK: - Decoders

extension LockingScriptBuilder where Self == MultiLockingScriptBuilder {
    static func bitcoin(isTestnet: Bool) -> Self {
        let network: UTXONetworkParams = isTestnet ? BitcoinTestnetNetworkParams() : BitcoinNetworkParams()
        return MultiLockingScriptBuilder(decoders: [SegWitDecoder(bech32Prefix: network.bech32), Base58Decoder(network: network)])
    }

    static func litecoin() -> Self {
        let network: UTXONetworkParams = LitecoinNetworkParams()
        return MultiLockingScriptBuilder(decoders: [SegWitDecoder(bech32Prefix: network.bech32), Base58Decoder(network: network)])
    }

    static func bitcoinCash(isTestnet: Bool) -> Self {
        let network: UTXONetworkParams = isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams()
        return MultiLockingScriptBuilder(decoders: [CashAddrDecoder(network: network), Base58Decoder(network: network)])
    }
}

// MARK: - Decoders

// Base58 (p2pkh and p2sh) addresses

extension LockingScriptBuilder where Self == Base58Decoder {
    static func dogecoin() -> Self {
        return Base58Decoder(network: DogecoinNetworkParams())
    }

    static func dash(isTestnet: Bool) -> Self {
        return Base58Decoder(network: isTestnet ? DashTestNetworkParams() : DashMainNetworkParams())
    }

    static func ravencoin(isTestnet: Bool) -> Self {
        return Base58Decoder(network: isTestnet ? RavencoinTestNetworkParams() : DashMainNetworkParams())
    }

    static func ducatus() -> Self {
        return Base58Decoder(network: DucatusNetworkParams())
    }

    static func kaspa() -> Self {
        return Base58Decoder(network: KaspaNetworkParams())
    }

    static func radiant() -> Self {
        return Base58Decoder(network: BitcoinCashNetworkParams())
    }
}

// MARK: - Decoders

extension LockingScriptBuilder where Self == SegWitDecoder {
    static func fact0rn() -> Self {
        return SegWitDecoder(bech32Prefix: Fact0rnMainNetworkParams().bech32)
    }
}
