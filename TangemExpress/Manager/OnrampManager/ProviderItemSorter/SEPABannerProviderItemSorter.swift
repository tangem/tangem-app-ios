//
//  SEPABannerProviderItemSorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension ProviderItemSorter where Self == SEPABannerProviderItemSorter {
    static var mercuryoWithSEPAPriority: Self { .init() }
}

public struct SEPABannerProviderItemSorter: ProviderItemSorter {
    private let priorityProvider: String = "mercuryo"
    private let priorityPaymentMethod: OnrampPaymentMethod.MethodType = .sepa

    private let defaultSorter: ProviderItemSorter = .default

    public func sort(lhs: OnrampProvider, rhs: OnrampProvider) -> Bool {
        switch (lhs.state, rhs.state) {
        case (.loaded, .loaded) where lhs.provider.id == "mercuryo":
            // Prioritise this pair of values
            return true
        default:
            return defaultSorter.sort(lhs: lhs, rhs: rhs)
        }
    }

    public func sort(lhs: OnrampPaymentMethod, rhs: OnrampPaymentMethod) -> Bool {
        if lhs.type == priorityPaymentMethod {
            return true
        }

        return defaultSorter.sort(lhs: lhs, rhs: rhs)
    }
}
