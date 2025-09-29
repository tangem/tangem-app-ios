//
//  ProviderItemSorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ProviderItemSorter {
    private let sortType: SortType

    public init(sortType: SortType) {
        self.sortType = sortType
    }

    public func sort(lhs: ProviderItem, rhs: ProviderItem) -> Bool {
        if sortType == .byPaymentMethodPriority {
            // If paymentMethod has same priority (e.g. SEPA and Revolut Pay)
            guard lhs.paymentMethod.type.priority == rhs.paymentMethod.type.priority else {
                return lhs.paymentMethod.type.priority > rhs.paymentMethod.type.priority
            }
        }

        switch (lhs.providers.first, rhs.providers.first) {
        case (.some(let lhsProvider), .some(let rhsProvider)):
            return lhsProvider > rhsProvider
        case (.none, _), (_, .none):
            return false
        }
    }
}

public extension ProviderItemSorter {
    enum SortType: Hashable {
        case byPaymentMethodPriority
        case byOnrampProviderExpectedAmount
    }
}
