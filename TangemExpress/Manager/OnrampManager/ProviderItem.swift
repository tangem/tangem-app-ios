//
//  ProviderItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public typealias ProvidersList = [ProviderItem]

public class ProviderItem {
    public let paymentMethod: OnrampPaymentMethod
    public private(set) var providers: [OnrampProvider]

    init(paymentMethod: OnrampPaymentMethod, providers: [OnrampProvider]) {
        self.paymentMethod = paymentMethod
        self.providers = providers
    }

    public func hasShowableProviders() -> Bool {
        providers.filter { $0.isShowable }.isNotEmpty
    }

    public func showableProvider() -> OnrampProvider? {
        providers.first(where: { $0.isShowable })
    }

    public func selectableProvider() -> OnrampProvider? {
        providers.first(where: { $0.isSelectable })
    }

    @discardableResult
    public func sort() -> [OnrampProvider] {
        providers.sort(by: { sort(lhs: $0, rhs: $1) })
        // Return sorted providers
        return providers
    }

    /// Providers will be sorted
    @discardableResult
    public func updateAttractiveTypes() -> OnrampProvider? {
        var bestQuote: Decimal?

        sort().indexed().forEach { index, provider in
            switch (index, provider.state) {
            case (.zero, .loaded(let quote)):
                provider.update(attractiveType: .best)
                bestQuote = quote.expectedAmount

            case (_, .loaded(let quote)) where bestQuote != nil:
                let percent = quote.expectedAmount / bestQuote! - 1
                provider.update(attractiveType: .loss(percent: percent))
            case (_, _):
                provider.update(attractiveType: .none)
            }
        }

        return nil
    }

    private func sort(lhs: OnrampProvider, rhs: OnrampProvider) -> Bool {
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
            let lhsDiff = (lhs.amount ?? 0) - (lhsRestriction.amount ?? 0)
            let rhsDiff = (rhs.amount ?? 0) - (rhsRestriction.amount ?? 0)
            return abs(lhsDiff) > abs(rhsDiff)
        case (.restriction, _):
            return true
        case (_, .restriction):
            return false
        default:
            return false
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension ProviderItem: CustomDebugStringConvertible {
    public var debugDescription: String {
        TangemFoundation.objectDescription(self, userInfo: [
            "paymentMethod": paymentMethod.name,
            "providers": providers.map {
                "providerName: \($0.provider.name), state: \($0.state)"
            },
        ])
    }
}

// MARK: - Array<ProviderItem>

public extension ProvidersList {
    func hasProviders() -> Bool {
        !flatMap { $0.providers }.isEmpty
    }

    func select(for paymentMethod: OnrampPaymentMethod) -> ProviderItem? {
        first(where: { $0.paymentMethod == paymentMethod })
    }
}
