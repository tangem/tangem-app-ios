//
//  BitcoinCashAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class BitcoinCashAddressService {
    private let base58LockingScriptBuilder: Base58LockingScriptBuilder
    private let cashAddrLockingScriptBuilder: CashAddrLockingScriptBuilder

    private let bech32Prefix: String

    init(networkParams: UTXONetworkParams) {
        base58LockingScriptBuilder = .init(network: networkParams)
        cashAddrLockingScriptBuilder = .init(network: networkParams)

        bech32Prefix = networkParams.bech32Prefix
    }
}

// MARK: - AddressValidator

extension BitcoinCashAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        if isLegacy(address) {
            return (try? base58LockingScriptBuilder.decode(address: address)) != nil
        }

        let address = address.contains(":") ? address : "\(bech32Prefix):\(address)"
        let decoded = try? cashAddrLockingScriptBuilder.decode(address: address)
        return decoded != nil
    }
}

// MARK: - AddressProvider

extension BitcoinCashAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        switch addressType {
        case .default:
            let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
            let (address, script) = try cashAddrLockingScriptBuilder.encode(publicKey: compressedKey, type: .p2pkh)
            return LockingScriptAddress(value: address, publicKey: publicKey, type: addressType, lockingScript: script)
        case .legacy:
            let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
            let (address, script) = try base58LockingScriptBuilder.encode(publicKey: compressedKey, type: .p2pkh)
            return LockingScriptAddress(value: address, publicKey: publicKey, type: addressType, lockingScript: script)
        }
    }
}

extension BitcoinCashAddressService {
    func isLegacy(_ address: String) -> Bool {
        (try? base58LockingScriptBuilder.decode(address: address)) != nil
    }
}
