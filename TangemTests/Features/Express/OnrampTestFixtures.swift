//
//  OnrampTestFixtures.swift
//  TangemTests
//
//  Created on 28.04.2026.
//

import Foundation
@testable import TangemExpress

enum OnrampTestFixtures {
    static func makeProvider(
        providerId: String = "mercuryo",
        paymentMethodId: String = "apple-pay",
        amount: Decimal? = 100,
        state: OnrampProviderManagerState = .loaded(OnrampQuote(expectedAmount: 100, nativePaymentAvailable: true, quoteId: "quote-id"))
    ) -> OnrampProvider {
        let provider = ExpressProvider(
            id: providerId,
            name: "Test",
            type: .onramp,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )

        let paymentMethod = OnrampPaymentMethod(
            id: paymentMethodId,
            name: "Apple Pay",
            image: URL(string: "https://example.com/icon.png")!
        )

        let manager = StubOnrampProviderManager(stateValue: state, amountValue: amount)

        return OnrampProvider(provider: provider, paymentMethod: paymentMethod, manager: manager)
    }
}

final class StubOnrampProviderManager: OnrampProviderManager {
    var amount: Decimal?
    var state: OnrampProviderManagerState

    init(stateValue: OnrampProviderManagerState, amountValue: Decimal?) {
        state = stateValue
        amount = amountValue
    }

    func update(supportedMethods: [OnrampPaymentMethod]) {}
    func update(amount: OnrampUpdatingAmount) async {}

    func makeOnrampQuotesRequestItem() throws -> OnrampQuotesRequestItem {
        throw OnrampProviderManagerError.amountNotFound
    }
}
