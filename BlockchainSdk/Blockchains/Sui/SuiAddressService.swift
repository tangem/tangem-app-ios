//
// SuiAddressService.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

final class SuiAddressService: AddressService {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> any Address {
        try WalletCoreAddressService(coin: .sui).makeAddress(for: publicKey, with: .default)
    }

    func validate(_ address: String) -> Bool {
        // Check the token contract address
        let coinType = try? SuiCoinObject.CoinType(string: address)

        // Check the user address
        let addressValid = WalletCoreAddressService(coin: .sui).validate(address)

        return coinType != nil || addressValid
    }
}
