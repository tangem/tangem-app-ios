//
//  OnrampManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampManager {
    // Load country by IP or get from repository
    func getCountry() async throws -> OnrampCountry

    // Load methods
    func updatePaymentMethod() async throws -> OnrampPaymentMethod

    // User did choose country. We prepare providers
    func update(pair: OnrampPair) async throws -> [OnrampProvider]

    // User did change amount. We load quotes providers
    func update(amount: Decimal) async throws -> [OnrampProvider]

    // load data to make onramp
    func loadOnrampData(request: OnrampSwappableItem) async throws -> OnrampRedirectData
}

public enum OnrampManagerError: LocalizedError {
    case notImplement
}
