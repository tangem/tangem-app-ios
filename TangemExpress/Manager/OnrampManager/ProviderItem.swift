//
//  ProviderItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public class ProviderItem: Identifiable {
    public var id: String { paymentMethod.id }

    public let paymentMethod: OnrampPaymentMethod
    public private(set) var providers: [OnrampProvider]

    init(
        paymentMethod: OnrampPaymentMethod,
        providers: [OnrampProvider]
    ) {
        self.paymentMethod = paymentMethod
        self.providers = providers
    }

    public func hasSuccessfullyLoadedProviders() -> Bool {
        !successfullyLoadedProviders().isEmpty
    }

    public func successfullyLoadedProviders() -> [OnrampProvider] {
        providers.filter { $0.isSuccessfullyLoaded }
    }

    public func hasSelectableProviders() -> Bool {
        !selectableProviders().isEmpty
    }

    public func selectableProviders() -> [OnrampProvider] {
        providers.filter { $0.isShowable && $0.isSelectable }
    }

    /// Provider which can be showed and selected
    public func maxPriorityProvider() -> OnrampProvider? {
        providers.first(where: { $0.isShowable && $0.isSelectable })
    }

    /// Provider which can be showed and selected
    public func preferredProvider(providerId: String) -> OnrampProvider? {
        providers.first(where: { $0.provider.id == providerId && $0.isShowable && $0.isSelectable })
    }

    /// Provider which can be selected by user
    public func selectableProvider() -> OnrampProvider? {
        providers.first(where: { $0.isSelectable })
    }

    @discardableResult
    public func sort() -> [OnrampProvider] {
        providers.sort()
        // Return sorted providers
        return providers
    }
}

// MARK: - CustomDebugStringConvertible

extension ProviderItem: CustomDebugStringConvertible {
    public var debugDescription: String {
        objectDescription(self, userInfo: [
            "paymentMethod": paymentMethod.name,
            "providers": providers.map {
                "providerName: \($0.provider.name), state: \($0.state)"
            },
        ])
    }
}
