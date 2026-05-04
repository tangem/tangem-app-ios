//
//  Wallet+AddressesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public extension Wallet {
    protocol AddressesProvider {
        var addresses: [Address] { get }
        var defaultAddress: Address { get }

        mutating func update(address: Address)
    }
}
