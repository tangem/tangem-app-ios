//
//  BitcoinCashAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
class BitcoinCashAddressService {
    private let legacyService: BitcoinLegacyAddressService
    private let cashAddrLockingScriptBuilder: CashAddrLockingScriptBuilder

    private let bech32Prefix: String

    init(networkParams: UTXONetworkParams) {
        legacyService = .init(networkParams: networkParams)
        cashAddrLockingScriptBuilder = .init(network: networkParams)

        bech32Prefix = networkParams.bech32Prefix
    }
}

// MARK: - AddressValidator

extension BitcoinCashAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        if isLegacy(address) {
            return legacyService.validate(address)
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
            let address = try legacyService.makeAddress(from: compressedKey)
            return address
        }
    }
}

extension BitcoinCashAddressService {
    func isLegacy(_ address: String) -> Bool {
        legacyService.validate(address)
    }
}
