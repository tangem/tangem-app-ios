//
//  CommonAddressesProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk

public struct CommonAddressesProvider {
    private(set) var _defaultAddress: Address
    private(set) var _legacyAddress: Address?

    public init(defaultAddress: Address, legacyAddress: Address? = nil) {
        _defaultAddress = defaultAddress
        _legacyAddress = legacyAddress
    }
}

// MARK: - Wallet.AddressesProvider

extension CommonAddressesProvider: Wallet.AddressesProvider {
    public var addresses: [any Address] {
        [_defaultAddress, _legacyAddress].compactMap(\.self)
    }

    public var defaultAddress: any Address {
        _defaultAddress
    }

    public var changeAddress: any Address {
        _defaultAddress
    }

    public mutating func update(address: any Address) {
        switch address.type {
        case .default: _defaultAddress = address
        case .legacy: _legacyAddress = address
        case .used: break
        }
    }

    public mutating func update(usedAddresses: [UTXOUsedAddress]) {}
}
