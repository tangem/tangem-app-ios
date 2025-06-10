//
//  RadiantAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class RadiantAddressService {
    private let builder: Base58LockingScriptBuilder

    init(network: UTXONetworkParams = RadiantNetworkParams()) {
        builder = .init(network: network)
    }
}

// MARK: - AddressValidator

extension RadiantAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        do {
            let (_, script) = try builder.decode(address: address)
            // Radiant supports only p2pkh addresses
            return script.type == .p2pkh
        } catch {
            return false
        }
    }
}

// MARK: - AddressProvider

extension RadiantAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressed = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let (address, script) = try builder.encode(publicKey: compressed, type: .p2pkh)

        return LockingScriptAddress(
            value: address,
            publicKey: publicKey,
            type: addressType,
            lockingScript: script
        )
    }
}
