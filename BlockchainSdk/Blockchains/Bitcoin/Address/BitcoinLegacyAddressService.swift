//
//  BitcoinLegacyAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class BitcoinLegacyAddressService {
    private let builder: Base58LockingScriptBuilder

    init(networkParams: UTXONetworkParams) {
        builder = .init(network: networkParams)
    }
}

// MARK: - BitcoinScriptAddressProvider

extension BitcoinLegacyAddressService: BitcoinScriptAddressProvider {
    func makeScriptAddress(redeemScript: Data) throws -> (address: String, script: UTXOLockingScript) {
        let (address, script) = try builder.encode(redeemScript: redeemScript, type: .p2sh)
        return (address, script)
    }
}

// MARK: - AddressValidator

extension BitcoinLegacyAddressService: AddressValidator {
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

extension BitcoinLegacyAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try publicKey.blockchainKey.validateAsSecp256k1Key()

        // "RUfZU5pNhBfEBvq1HmE6zCNTMDMiiPoa6D" - 191
        // "REz2nSPBJXbtADutx1tG27B8PUTJYP7yNv" - 31
        let (address, lockingScript) = try builder.encode(publicKey: publicKey.blockchainKey, type: .p2pkh)
        return LockingScriptAddress(value: "REz2nSPBJXbtADutx1tG27B8PUTJYP7yNv", publicKey: publicKey, type: addressType, lockingScript: lockingScript)
    }
}
