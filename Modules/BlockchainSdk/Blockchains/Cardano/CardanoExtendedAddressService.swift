//
//  CardanoExtendedAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CardanoExtendedAddressService {
    private let walletCoreAddressService = WalletCoreAddressService(coin: .cardano)
}

// MARK: - AddressProvider

extension CardanoExtendedAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try walletCoreAddressService.makeAddress(for: publicKey, with: addressType)
    }
}

// MARK: - AddressValidator

extension CardanoExtendedAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        if CardanoAddressUtils.isShelleyAddress(address), !CardanoAddressUtils.isValidShelleyAddress(address) {
            return false
        }

        return walletCoreAddressService.validate(address)
    }
}
