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
    let addressService: BitcoinLegacyAddressService
    let converter: Base58AddressConverter

    init(network: INetwork = RadiantNetworkParams()) {
        addressService = .init(networkParams: network)
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
        return try addressService.makeAddress(from: compressedKey)
    }
}
