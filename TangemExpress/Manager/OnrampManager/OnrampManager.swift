//
//  OnrampManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public protocol OnrampManager: Actor {
    var providers: [OnrampProvider] { get }
    var selectedProvider: OnrampProvider? { get }

    /// Initial loading country by IP
    /// If the country has already been setup then return nil
    func initialSetupCountry() async throws -> OnrampCountry

    /// Determine the payment method that you will be offered to use
    func initialSetupPaymentMethod() async throws -> OnrampPaymentMethod

    /// User has selected a currency. We are preparing onramp providers
    func setupProviders(request: OnrampPairRequestItem) async throws

    /// The user changed the amount. We upload providers quotes
    func setupQuotes(amount: Decimal?) async throws

    /// Load the data to perform the onramp action
    func loadOnrampData(request: OnrampQuotesRequestItem) async throws -> OnrampRedirectData
}

public enum OnrampManagerError: LocalizedError {
    case notImplement
}
