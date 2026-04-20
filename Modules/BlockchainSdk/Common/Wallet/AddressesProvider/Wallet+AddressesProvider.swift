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

        /// Used for dynamic address feature where the user can have a few public keys on different derivations and addresses for them.
        mutating func update(userDerivations: [DerivationPath])
    }
}
