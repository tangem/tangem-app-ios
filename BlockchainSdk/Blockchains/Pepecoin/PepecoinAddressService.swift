//
//  PepecoinAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

class PepecoinAddressService {
    private let converter: IAddressConverter

    init(isTestnet: Bool) {
        let networkParams: INetwork = isTestnet ? PepecoinTestnetNetworkParams() : PepecoinMainnetNetworkParams()
        converter = Base58AddressConverter(addressVersion: networkParams.pubKeyHash, addressScriptVersion: networkParams.scriptHash)
    }
}

// MARK: - BitcoinScriptAddressProvider

@available(iOS 13.0, *)
extension PepecoinAddressService: BitcoinScriptAddressProvider {
    func makeScriptAddress(from scriptHash: Data) throws -> String {
        return try converter.convert(keyHash: scriptHash, type: .p2sh).stringValue
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension PepecoinAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        do {
            _ = try converter.convert(address: address)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension PepecoinAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try publicKey.blockchainKey.validateAsSecp256k1Key()

        // Workaround for similar address legacy cards
        let compressedPublicKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()

        let bitcoinCorePublicKey = PublicKey(
            withAccount: 0,
            index: 0,
            external: true,
            hdPublicKeyData: compressedPublicKey
        )

        let address = try converter.convert(publicKey: bitcoinCorePublicKey, type: .p2pkh)
        return LockingScriptAddress(
            value: address.stringValue,
            publicKey: publicKey,
            type: addressType,
            lockingScript: .init(data: address.lockingScript, type: .p2pkh)
        )
    }
}
