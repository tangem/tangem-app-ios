//
//  BitcoinAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
struct BitcoinAddressService {
    let legacy: BitcoinLegacyAddressService
    let bech32: BitcoinBech32AddressService
    let taproot: BitcoinTaprootAddressService

    init(networkParams: UTXONetworkParams) {
        legacy = BitcoinLegacyAddressService(networkParams: networkParams)
        bech32 = BitcoinBech32AddressService(networkParams: networkParams)
        taproot = BitcoinTaprootAddressService(networkParams: networkParams)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension BitcoinAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        legacy.validate(address) || bech32.validate(address) || taproot.validate(address)
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension BitcoinAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        switch addressType {
        case .default:
            return try bech32.makeAddress(for: publicKey, with: addressType)
        case .legacy:
            return try legacy.makeAddress(for: publicKey, with: addressType)
        }
    }
}

// MARK: - BitcoinScriptAddressProvider

@available(iOS 13.0, *)
extension BitcoinAddressService: BitcoinScriptAddressesProvider {
    func makeAddresses(publicKey: Wallet.PublicKey, pairPublicKey: Data) throws -> [LockingScriptAddress] {
        let compressedKeys = try [publicKey.blockchainKey, pairPublicKey].map {
            try Secp256k1Key(with: $0).compress()
        }

        let redeemScript = try BitcoinScriptBuilder().makeMultisig(publicKeys: compressedKeys, signaturesRequired: 1)
        let (legacyAddressValue, legacyScript) = try legacy.makeScriptAddress(redeemScript: redeemScript.data)
        let legacyAddress = LockingScriptAddress(value: legacyAddressValue, publicKey: publicKey, type: .legacy, lockingScript: legacyScript)

        let (bech32AddressValue, bech32Script) = try bech32.makeScriptAddress(redeemScript: redeemScript.data)
        let bech32Address = LockingScriptAddress(value: bech32AddressValue, publicKey: publicKey, type: .default, lockingScript: bech32Script)

        return [bech32Address, legacyAddress]
    }
}
