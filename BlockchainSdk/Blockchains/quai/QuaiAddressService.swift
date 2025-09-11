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
        try evmAddressService.makeAddress(for: publicKey, with: addressType)
    }
}

// MARK: - AddressValidator

extension QuaiAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        evmAddressService.validate(address)
    }
}
