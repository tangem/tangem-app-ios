//
//  AddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias AddressService = AddressProvider & AddressValidator

public protocol AddressValidator {
    func validate(_ address: String) -> Bool
    func validateCustomTokenAddress(_ address: String) -> Bool
    func resolveAddress(_ address: String) -> String
    /// Unlike `validate(_:)`, rejects domain names that require `AddressResolver` resolution (e.g. ENS).
    func validatePlainAddress(_ address: String) -> Bool
}

public extension AddressValidator {
    func validateCustomTokenAddress(_ address: String) -> Bool {
        validate(address)
    }

    func resolveAddress(_ address: String) -> String {
        return address
    }

    func validatePlainAddress(_ address: String) -> Bool {
        validate(address)
    }
}

public protocol AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address
}

public protocol AddressAdditionalFieldService {
    func canEmbedAdditionalField(into address: String) -> Bool
}

/// A convenient extension for using a raw public key
extension AddressProvider {
    func makeAddress(from publicKey: Data, type: AddressType = .default) throws -> Address {
        try makeAddress(for: Wallet.PublicKey(seedKey: publicKey, derivationType: .none), with: type)
    }
}
