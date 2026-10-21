//
//  PolymarketAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol PolymarketAvailabilityProvider {
    var isAvailablePublisher: AnyPublisher<Bool, Never> { get }

    func isAvailablePublisher(hasAccount: @escaping () -> Bool) -> AnyPublisher<Bool, Never>
}

/// A wallet that already has an account keeps the feature on its own, without the toggle.
struct CommonPolymarketAvailabilityProvider: PolymarketAvailabilityProvider {
    var isAvailable: Bool {
        FeatureProvider.isAvailable(.polymarket)
    }

    var isAvailablePublisher: AnyPublisher<Bool, Never> {
        Just(isAvailable).eraseToAnyPublisher()
    }

    func isAvailable(hasAccount: () -> Bool) -> Bool {
        hasAccount() || isAvailable
    }

    func isAvailablePublisher(hasAccount: @escaping () -> Bool) -> AnyPublisher<Bool, Never> {
        Just(isAvailable(hasAccount: hasAccount)).eraseToAnyPublisher()
    }
}

// MARK: - Injection

private struct PolymarketAvailabilityProviderKey: InjectionKey {
    static var currentValue: PolymarketAvailabilityProvider = CommonPolymarketAvailabilityProvider()
}

extension InjectedValues {
    var polymarketAvailabilityProvider: PolymarketAvailabilityProvider {
        get { Self[PolymarketAvailabilityProviderKey.self] }
        set { Self[PolymarketAvailabilityProviderKey.self] = newValue }
    }
}
