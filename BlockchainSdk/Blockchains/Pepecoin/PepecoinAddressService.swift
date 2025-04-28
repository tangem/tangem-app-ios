//
//  PepecoinAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class PepecoinAddressService {
    private let builder: Base58LockingScriptBuilder

    init(isTestnet: Bool) {
        let networkParams: UTXONetworkParams = isTestnet ? PepecoinTestnetNetworkParams() : PepecoinMainnetNetworkParams()
        builder = .init(network: networkParams)
    }
}

// MARK: - AddressValidator

extension PepecoinAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        do {
            _ = try builder.decode(address: address)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - AddressProvider

extension PepecoinAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressed = try Secp256k1Key(with: publicKey.blockchainKey).compress()

        let (address, lockingScript) = try builder.encode(publicKey: compressed, type: .p2pkh)
        return LockingScriptAddress(value: address, publicKey: publicKey, type: addressType, lockingScript: lockingScript)
    }
}
