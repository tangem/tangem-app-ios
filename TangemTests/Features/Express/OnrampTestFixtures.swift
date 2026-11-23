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
        state: OnrampProviderManagerState = .loaded(OnrampQuote(expectedAmount: 100, nativePaymentAvailable: true, quoteId: "quote-id", isRestricted: false))
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
            slippage: nil,
            isCustomSlippageSupported: false
        )

        let paymentMethod = OnrampPaymentMethod(
            id: paymentMethodId,
            name: "Apple Pay",
            image: URL(string: "https://example.com/icon.png")!
        )

        let manager = StubOnrampProviderManager(stateValue: state, amountValue: amount)

        return OnrampProvider(provider: provider, paymentMethod: paymentMethod, manager: manager)
    }

    static func makeProvidersList(_ providers: [OnrampProvider]) -> ProvidersList {
        let grouped = Dictionary(grouping: providers, by: { $0.paymentMethod.id })
        let items = grouped.map { _, providers in
            ProviderItem(paymentMethod: providers[0].paymentMethod, providers: providers)
        }
        items.forEach { $0.sort() }
        let list: ProvidersList = items
        list.updateAttractiveTypes()
        list.updateProcessingTimeTypes(preferredProviderId: nil)
        return list
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

actor OnrampManagerStub: OnrampManager {
    private var ipCountry: OnrampCountry?

    init(ipCountry: OnrampCountry? = nil) {
        self.ipCountry = ipCountry
    }

    func setIPCountry(_ country: OnrampCountry?) {
        ipCountry = country
    }

    func initialSetupCountry() async throws -> OnrampCountry {
        guard let ipCountry else {
            throw OnrampManagerError.providersIsEmpty
        }

        return ipCountry
    }

    func setupProviders(request: OnrampPairRequestItem) async throws -> ProvidersList {
        throw OnrampManagerError.providersIsEmpty
    }

    func setupQuotes(in providers: ProvidersList, amount: OnrampUpdatingAmount) async throws -> (list: ProvidersList, provider: OnrampProvider) {
        throw OnrampManagerError.providersIsEmpty
    }

    func loadRedirectData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings) async throws -> OnrampRedirectData {
        throw OnrampManagerError.providersIsEmpty
    }

    func loadNativePaymentData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings, applePayResult: OnrampApplePayResult) async throws -> OnrampDataResult {
        throw OnrampManagerError.providersIsEmpty
    }

    func findRecentOnrampTransaction(
        payoutAddress: String,
        since: Date,
        toContractAddress: String,
        toNetwork: String,
        providerId: ExpressProvider.Id,
        limit: Int?
    ) async throws -> OnrampTransaction? { nil }
}

actor OnrampDataRepositoryStub: OnrampDataRepository {
    private let listedCountries: [OnrampCountry]
    private let listedCurrencies: [OnrampFiatCurrency]
    private var isCountriesFailing = false

    init(countries: [OnrampCountry] = [], currencies: [OnrampFiatCurrency] = []) {
        listedCountries = countries
        listedCurrencies = currencies
    }

    func failCountries() {
        isCountriesFailing = true
    }

    func providers() async throws -> [ExpressProvider] { [] }
    func paymentMethods() async throws -> [OnrampPaymentMethod] { [] }

    func countries() async throws -> [OnrampCountry] {
        if isCountriesFailing {
            throw URLError(.notConnectedToInternet)
        }

        return listedCountries
    }

    func currencies() async throws -> [OnrampFiatCurrency] { listedCurrencies }
}
