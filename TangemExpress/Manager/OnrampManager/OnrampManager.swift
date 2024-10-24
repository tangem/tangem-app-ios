//
//  OnrampManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampManager {
    // Load country by IP or get from repository
    func getCountry() async throws -> OnrampCountry

    // User did choose currency. We prepare providers
    func loadProviders(request: OnrampPairRequestItem) async throws

    // User did change amount. We load quotes providers
    func loadQuotes(amount: Decimal) async throws

    // load data to make onramp
    func loadOnrampData(request: OnrampSwappableItem) async throws -> OnrampRedirectData
}

public enum OnrampManagerError: LocalizedError {
    case notImplement
}
