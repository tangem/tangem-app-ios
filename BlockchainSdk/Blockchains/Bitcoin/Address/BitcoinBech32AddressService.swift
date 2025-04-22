//
//  BitcoinBech32AddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class BitcoinBech32AddressService {
    private let segWitBuilder: SegWitLockingScriptBuilder

    init(networkParams: UTXONetworkParams) {
        segWitBuilder = .init(network: networkParams)
    }
}

// MARK: - BitcoinScriptAddressProvider

extension BitcoinBech32AddressService: BitcoinScriptAddressProvider {
    func makeScriptAddress(redeemScript: Data) throws -> (address: String, script: UTXOLockingScript) {
        let scriptHash = redeemScript.sha256()
        let (address, script) = try segWitBuilder.encode(keyHash: scriptHash, type: .p2wsh(redeemScript: redeemScript))
        return (address, script)
    }
}

// MARK: - AddressValidator

extension BitcoinBech32AddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        let segwitAddress = try? segWitBuilder.decode(address: address)
        return segwitAddress != nil
    }
}

// MARK: - AddressProvider

extension BitcoinBech32AddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()

        let (address, lockingScript) = try segWitBuilder.encode(publicKey: compressedKey, type: .p2wpkh)
        return LockingScriptAddress(value: address, publicKey: publicKey, type: addressType, lockingScript: lockingScript)
    }
}
