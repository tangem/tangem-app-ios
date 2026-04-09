//
//  Wallet+AddressesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public extension Wallet {
    protocol AddressesProvider {
        var defaultAddress: Address { get }
        var legacyAddress: Address? { get }

        mutating func update(address: Address)
    }
}

extension Wallet.AddressesProvider {
    var addresses: [Address] {
        [defaultAddress, legacyAddress].compactMap { $0 }
    }
}
