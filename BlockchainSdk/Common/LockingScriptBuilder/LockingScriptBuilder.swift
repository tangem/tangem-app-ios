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
    case wrongBech32Prefix
    case unsupportedVersion
    case lockingScriptNotFound
}

// MARK: - Decoders

// MARK: - MultiLockingScriptBuilder

extension LockingScriptBuilder where Self == MultiLockingScriptBuilder {
    static func bitcoin(isTestnet: Bool) -> Self {
        let network: UTXONetworkParams = isTestnet ? BitcoinTestnetNetworkParams() : BitcoinNetworkParams()
        return MultiLockingScriptBuilder(decoders: [SegWitDecoder(network: network), Base58Decoder(network: network)])
    }

    static func litecoin() -> Self {
        let network: UTXONetworkParams = LitecoinNetworkParams()
        return MultiLockingScriptBuilder(decoders: [SegWitDecoder(network: network), Base58Decoder(network: network)])
    }

    static func bitcoinCash(isTestnet: Bool) -> Self {
        let network: UTXONetworkParams = isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams()
        return MultiLockingScriptBuilder(decoders: [CashAddrDecoder(network: network), Base58Decoder(network: network)])
    }
}

// MARK: - Base58Decoder

extension LockingScriptBuilder where Self == Base58Decoder {
    static func dogecoin() -> Self {
        return Base58Decoder(network: DogecoinNetworkParams())
    }

    static func dash(isTestnet: Bool) -> Self {
        return Base58Decoder(network: isTestnet ? DashTestNetworkParams() : DashMainNetworkParams())
    }

    static func ravencoin(isTestnet: Bool) -> Self {
        return Base58Decoder(network: isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams())
    }

    static func ducatus() -> Self {
        return Base58Decoder(network: DucatusNetworkParams())
    }

    static func clore() -> Self {
        return Base58Decoder(network: CloreMainNetworkParams())
    }

    static func radiant() -> Self {
        return Base58Decoder(network: BitcoinCashNetworkParams())
    }
}

// MARK: - KaspaAddressDecoder

extension LockingScriptBuilder where Self == KaspaAddressDecoder {
    static func kaspa() -> Self {
        return KaspaAddressDecoder(network: KaspaNetworkParams())
    }
}

// MARK: - SegWitDecoder

extension LockingScriptBuilder where Self == SegWitDecoder {
    static func fact0rn() -> Self {
        return SegWitDecoder(network: Fact0rnMainNetworkParams())
    }
}
