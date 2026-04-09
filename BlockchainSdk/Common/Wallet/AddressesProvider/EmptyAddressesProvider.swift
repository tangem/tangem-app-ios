//
//  EmptyAddressesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct EmptyAddressesProvider: Wallet.AddressesProvider {
    private let emptyAddress = EmptyAddress()

    public init() {}

    public var defaultAddress: any Address { emptyAddress }
    public var legacyAddress: (any Address)? { nil }

    public mutating func update(address: any Address) {}
}

public struct EmptyAddress: Address {
    public let value: String = "empty"
    public let type: AddressType = .default
    public var localizedName: String { type.defaultLocalizedName }

    public init() {}
}
