//
//  OnrampProviderManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

// For every onramp provider
public protocol OnrampProviderManager: Actor {
    // Update quotes for amount
    func update(amount: Decimal) async -> OnrampProviderManagerState

    // Get actual state
    func state() -> OnrampProviderManagerState
}

public enum OnrampProviderManagerState: Hashable {
    case created
    case loading
    case failed(error: String)
    case loaded(quote: OnrampQuote)
}
