//
//  EmptyAddressesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk

public struct EmptyAddressesProvider: Wallet.AddressesProvider {
    private let emptyAddress = EmptyAddress()

    public init() {}

    public var addresses: [any Address] { [emptyAddress] }
    public var defaultAddress: any Address { emptyAddress }
    public var changeAddress: any Address { emptyAddress }

    public mutating func update(address: any Address) {}
    public mutating func update(usedAddresses: [UTXOUsedAddress]) {}
}

public struct EmptyAddress: Address {
    public let value: String = "empty"
    public let type: AddressType = .default
    public var localizedName: String { type.defaultLocalizedName }

    public init() {}
}
