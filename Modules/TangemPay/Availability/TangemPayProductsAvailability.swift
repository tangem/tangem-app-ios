//
//  TangemPayProductsAvailability.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemPayProductsAvailability: Equatable {
    public let availableProducts: Set<TangemPayProduct>

    public init(availableProducts: Set<TangemPayProduct>) {
        self.availableProducts = availableProducts
    }

    public var isCardAvailable: Bool {
        availableProducts.contains(.paymentAccount)
    }

    public var isAccountAvailable: Bool {
        availableProducts.contains(.bankingAccount)
    }
}
