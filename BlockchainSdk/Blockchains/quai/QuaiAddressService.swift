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
import TangemFoundation

struct QuaiAddressService {
    private let evmAddressService = EVMAddressService()
}

// MARK: - AddressProvider

extension QuaiAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        guard let extendedPublicKey = publicKey.derivationType?.hdKey.extendedPublicKey else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }

        let addressUtility = QuaiAddressUtils(addressService: evmAddressService, expectedZone: .cyprus1)
        let derivedAddress = try addressUtility.derive(extendendPublicKey: extendedPublicKey, with: addressType)

        return derivedAddress
    }
}

// MARK: - AddressValidator

extension QuaiAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        evmAddressService.validate(address)
    }
}
