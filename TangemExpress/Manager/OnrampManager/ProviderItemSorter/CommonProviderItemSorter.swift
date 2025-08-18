//
//  CommonProviderItemSorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension ProviderItemSorter where Self == CommonProviderItemSorter {
    static var `default`: Self { .init() }
}

public struct CommonProviderItemSorter: ProviderItemSorter {
    public func sort(lhs: OnrampProvider, rhs: OnrampProvider) -> Bool {
        switch (lhs.state, rhs.state) {
        case (.loaded(let lhsQuote), .loaded(let rhsQuote)):
            return lhsQuote.expectedAmount > rhsQuote.expectedAmount
        // All cases which is not `loaded` have to be ordered after
        case (_, .loaded):
            return false
        // All cases which is `loaded` have to be ordered before `rhs`
        // Exclude case where `rhs == .loaded`. This case processed above
        case (.loaded, _):
            return true
        case (.restriction(let lhsRestriction), .restriction(let rhsRestriction)):
            let lhsDiff = (lhs.amount ?? 0) - lhsRestriction.amount
            let rhsDiff = (rhs.amount ?? 0) - rhsRestriction.amount
            return abs(lhsDiff) < abs(rhsDiff)
        case (.restriction, _):
            return true
        case (_, .restriction):
            return false
        default:
            return false
        }
    }

    public func sort(lhs: OnrampPaymentMethod, rhs: OnrampPaymentMethod) -> Bool {
        lhs.type.priority > rhs.type.priority
    }
}
