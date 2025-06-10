//
//  KoinosAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct KoinosAddressService {
    private let base58LockingScriptBuilder: Base58LockingScriptBuilder

    init(networkParams: UTXONetworkParams) {
        base58LockingScriptBuilder = .init(network: networkParams)
    }
}

// MARK: - AddressProvider

extension KoinosAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let (address, script) = try base58LockingScriptBuilder.encode(publicKey: compressedKey, type: .p2pkh)
        return LockingScriptAddress(value: address, publicKey: publicKey, type: addressType, lockingScript: script)
    }
}

// MARK: - AddressValidator

extension KoinosAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        (try? base58LockingScriptBuilder.decode(address: address)) != nil
    }
}
