//
//  Fact0rnAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct Fact0rnAddressService {
    private let bitcoinAddressService = BitcoinBech32AddressService(networkParams: Fact0rnMainNetworkParams())
}

// MARK: - AddressProvider

extension Fact0rnAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let address = try bitcoinAddressService.makeAddress(for: publicKey, with: addressType)
        return address
    }
}

// MARK: - AddressValidator

extension Fact0rnAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        bitcoinAddressService.validate(address)
    }
}
