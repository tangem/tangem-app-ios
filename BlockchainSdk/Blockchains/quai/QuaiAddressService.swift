//
//  QuaiAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoSwift

struct QuaiAddressService {
    private let evmAddressService = EVMAddressService()
}

// MARK: - AddressProvider

extension QuaiAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        print("blockchainKey: \(publicKey.blockchainKey.hexString)")
        print("seedKey: \(publicKey.seedKey.hexString)")

        let hdKey = publicKey.derivationType!.hdKey
        let derivationPath = hdKey.path
        let extendedPublicKey = publicKey.derivationType!.hdKey.extendedPublicKey

        for idx in 0 ... 32 {
            let newDerivationPath = derivationPath.extendedPath(with: .nonHardened(UInt32(31)))
            do {
                let derivedKey = try publicKey.derivationType?
                    .hdKey
                    .extendedPublicKey.derivePublicKey(node: .nonHardened(UInt32(31)))

                print(derivedKey?.publicKey.hexString)

                let publicKey = Wallet.PublicKey(seedKey: derivedKey!.publicKey, derivationType: .none)
                let address = try evmAddressService.makeAddress(for: publicKey, with: addressType)
                print("address = \(address.value) for index = \(idx)")
            } catch {
                print(error)
                throw error
            }
        }

        return try evmAddressService.makeAddress(for: publicKey, with: addressType)
    }
}

// MARK: - AddressValidator

extension QuaiAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        evmAddressService.validate(address)
    }
}
