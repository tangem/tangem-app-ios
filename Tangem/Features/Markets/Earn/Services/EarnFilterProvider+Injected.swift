//
//  EarnFilterProvider+Injected.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - InjectedValues + earnDataFilterProvider

/// Injected Earn filter provider. Per task requirements, filter state (network, type) must be preserved for the app session — a single instance per key ensures this.
extension InjectedValues {
    var earnDataFilterProvider: EarnDataFilterProvider {
        get { Self[EarnDataFilterProviderKey.self] }
        set { Self[EarnDataFilterProviderKey.self] = newValue }
    }
}

// MARK: - EarnDataFilterProviderKey

private struct EarnDataFilterProviderKey: InjectionKey {
    static var currentValue: EarnDataFilterProvider = EarnDataFilterProvider()
}
