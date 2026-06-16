//
//  Wallet+AddressesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk

public extension Wallet {
    protocol AddressesProvider {
        var addresses: [Address] { get }
        var defaultAddress: Address { get }
        var changeAddress: any Address { get }

        mutating func update(address: Address)

        /// Used for the dynamic address feature where the user can have multiple used addresses,
        /// each associated with its derivation path.
        mutating func update(usedAddresses: [UTXOUsedAddress])
    }
}
