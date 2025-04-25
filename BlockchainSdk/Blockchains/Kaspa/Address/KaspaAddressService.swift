//
//  KaspaAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class KaspaAddressService {
    private let lockingScriptBuilder: KaspaAddressLockingScriptBuilder

    init(isTestnet: Bool) {
        let network: UTXONetworkParams = isTestnet ? KaspaTestNetworkParams() : KaspaNetworkParams()
        lockingScriptBuilder = KaspaAddressLockingScriptBuilder(network: network)
    }

    func scriptPublicKey(address: String) throws -> Data {
        try lockingScriptBuilder.lockingScript(for: address).data
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension KaspaAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let (address, lockingScript) = try lockingScriptBuilder.encode(publicKey: compressedKey, type: .p2pk)
        return LockingScriptAddress(value: address, publicKey: publicKey, type: addressType, lockingScript: lockingScript)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension KaspaAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        let script = try? lockingScriptBuilder.lockingScript(for: address)
        guard script != nil else {
            return false
        }

        let components = address.components(separatedBy: ":")
        guard components.count == 2 else {
            return false
        }

        guard let firstAddressLetter = components.last?.first else {
            return false
        }

        let validStartLetters = ["q", "p"]
        guard validStartLetters.contains(String(firstAddressLetter)) else {
            return false
        }

        return true
    }
}
