//
//  OnrampRedirectingInteractorTests.swift
//  TangemTests
//
//  Created on 20.10.2026.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("CommonOnrampRedirectingInteractor")
struct OnrampRedirectingInteractorTests {
    @Test("Redirect data is handed over with the provider it was loaded for, even if the selection changed meanwhile")
    func handsOverLoadedProvider() async throws {
        let io = StubOnrampRedirectingIO(selectedOnrampProvider: OnrampTestFixtures.makeProvider(providerId: "mercuryo"))
        let manager = StubRedirectOnrampManager {
            io.selectedOnrampProvider = OnrampTestFixtures.makeProvider(providerId: "moonpay")
        }
        let interactor = CommonOnrampRedirectingInteractor(
            input: io,
            output: io,
            onrampManager: manager,
            redirectSettingsBuilder: OnrampRedirectSettingsBuilder()
        )

        try await interactor.loadRedirectData(theme: .light)

        #expect(io.loadedProvider?.provider.id == "mercuryo")
    }
}

// MARK: - Stubs

private final class StubOnrampRedirectingIO: OnrampRedirectingInput, OnrampRedirectingOutput {
    var selectedOnrampProvider: OnrampProvider?
    private(set) var loadedProvider: OnrampProvider?

    init(selectedOnrampProvider: OnrampProvider) {
        self.selectedOnrampProvider = selectedOnrampProvider
    }

    func redirectDataDidLoad(data: OnrampRedirectData, provider: OnrampProvider) {
        loadedProvider = provider
    }
}

private actor StubRedirectOnrampManager: OnrampManager {
    private let onLoadRedirectData: () -> Void

    init(onLoadRedirectData: @escaping () -> Void) {
        self.onLoadRedirectData = onLoadRedirectData
    }

    func initialSetupCountry() async throws -> OnrampCountry {
        fatalError("not used")
    }

    func setupProviders(request: OnrampPairRequestItem) async throws -> ProvidersList {
        fatalError("not used")
    }

    func setupQuotes(in providers: ProvidersList, amount: OnrampUpdatingAmount) async throws -> (list: ProvidersList, provider: OnrampProvider) {
        fatalError("not used")
    }

    func loadRedirectData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings) async throws -> OnrampRedirectData {
        onLoadRedirectData()

        return OnrampRedirectData(
            txId: "widget-tx",
            widgetURL: URL(string: "https://example.com/widget")!,
            redirectURL: URL(string: "https://example.com/redirect")!,
            fromAmount: 100,
            fromCurrencyCode: "EUR",
            toAmount: nil,
            countryCode: "",
            externalTxId: nil,
            externalTxURL: nil
        )
    }

    func loadNativePaymentData(
        provider: OnrampProvider,
        redirectSettings: OnrampRedirectSettings,
        applePayResult: OnrampApplePayResult
    ) async throws -> OnrampDataResult {
        fatalError("not used")
    }

    func findRecentOnrampTransaction(
        payoutAddress: String,
        since: Date,
        toContractAddress: String,
        toNetwork: String,
        providerId: ExpressProvider.Id,
        limit: Int?
    ) async throws -> OnrampTransaction? {
        fatalError("not used")
    }
}
