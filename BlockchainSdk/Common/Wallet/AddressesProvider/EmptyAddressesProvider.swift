//
//  EmptyAddressesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct EmptyAddressesProvider: Wallet.AddressesProvider {
    public init() {}

    public var addresses: [any Address] { [] }
    public var defaultAddress: any Address {
        fatalError("EmptyAddressesProvider doesn't have a default address")
    }

    public var changeAddress: any Address {
        fatalError("EmptyAddressesProvider doesn't have a change address")
    }

    public mutating func update(address: any Address) {}
}
