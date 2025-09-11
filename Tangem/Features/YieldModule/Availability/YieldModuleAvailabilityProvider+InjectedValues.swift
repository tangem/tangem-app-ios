//
//  YieldModuleAvailabilityProvider+InjectedValues.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension InjectedValues {
    var yieldModuleAvailabilityProvider: YieldModuleAvailabilityProvider {
        get { Self[YieldModuleAvailabilityProviderKey.self] }
        set { Self[YieldModuleAvailabilityProviderKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct YieldModuleAvailabilityProviderKey: InjectionKey {
    static var currentValue: YieldModuleAvailabilityProvider = CommonYieldModuleAvailabilityProvider()
}
