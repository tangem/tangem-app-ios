//
//  ProviderItemSorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol ProviderItemSorter {
    func sort(lhs: ProviderItem, rhs: ProviderItem) -> Bool
}

public struct ProviderItemSorterByPaymentMethodPriority: ProviderItemSorter {
    public init() {}

    public func sort(lhs: ProviderItem, rhs: ProviderItem) -> Bool {
        // If paymentMethod has same priority (e.g. SEPA and Revolut Pay)
        guard lhs.paymentMethod.type.priority == rhs.paymentMethod.type.priority else {
            return lhs.paymentMethod.type.priority > rhs.paymentMethod.type.priority
        }

        switch (lhs.providers.first, rhs.providers.first) {
        case (.some(let lhsProvider), .some(let rhsProvider)):
            return lhsProvider > rhsProvider
        case (.none, _), (_, .none):
            return false
        }
    }
}

public struct ProviderItemSorterByOnrampProviderExpectedAmount: ProviderItemSorter {
    public init() {}

    public func sort(lhs: ProviderItem, rhs: ProviderItem) -> Bool {
        switch (lhs.providers.first, rhs.providers.first) {
        case (.some(let lhsProvider), .some(let rhsProvider)):
            return lhsProvider > rhsProvider
        case (.none, _), (_, .none):
            return false
        }
    }
}
