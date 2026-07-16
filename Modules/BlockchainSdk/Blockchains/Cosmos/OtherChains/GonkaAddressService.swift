//
//  GonkaAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct GonkaAddressService {}

// MARK: - AddressValidator

extension GonkaAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard address.starts(with: Constants.hrp + "1") else {
            return false
        }

        return (try? Bech32().decode(address)) != nil
    }
}

// MARK: - AddressProvider

extension GonkaAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let compressedKey = try Secp256k1Key(with: publicKey.blockchainKey).compress()
        let address = try Bech32().encode(Constants.hrp, values: compressedKey.sha256Ripemd160)
        return PlainAddress(value: address, type: addressType)
    }
}

private extension GonkaAddressService {
    enum Constants {
        static let hrp = "gonka"
    }
}
