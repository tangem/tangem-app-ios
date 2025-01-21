//
//  AlephiumAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumAddressService {}

// MARK: - AddressProvider

extension AlephiumAddressService: AddressProvider, AddressValidator {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> any Address {
        // [REDACTED_TODO_COMMENT]
        throw WalletError.empty
    }

    func validate(_ address: String) -> Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }
}
