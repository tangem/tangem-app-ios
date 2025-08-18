//
//  ProviderItemSorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol ProviderItemSorter {
    /// Sort by state inside the same payment type
    func sort(lhs: OnrampProvider, rhs: OnrampProvider) -> Bool

    /// Sorting payment types
    func sort(lhs: OnrampPaymentMethod, rhs: OnrampPaymentMethod) -> Bool
}
