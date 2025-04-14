//
//  RadiantAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

class RadiantAddressService {
    let converter: Base58AddressConverter

    init(network: INetwork = RadiantNetworkParams()) {
        converter = .init(addressVersion: network.pubKeyHash, addressScriptVersion: network.scriptHash)
    }
}

// MARK: - AddressValidator

extension RadiantAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        do {
            let address = try converter.convert(address: address)
            // Radiant supports only p2pkh addresses
            return address.scriptType == .p2pkh
        } catch {
            return false
        }
    }
}

// MARK: - AddressProvider

extension RadiantAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        try compressedKey.validateAsSecp256k1Key()

        let bitcoinCorePublicKey = PublicKey(
            withAccount: 0,
            index: 0,
            external: true,
            hdPublicKeyData: compressedKey
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
