//
//  CEXProviderFlowHelperExchangeDataErrorTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("CEXProviderFlowHelper — errors of the lazy exchange-data request")
struct CEXProviderFlowHelperExchangeDataErrorTests {
    @Test("An exchange-data failure carries the provider and the currency the amount was entered in")
    func exchangeDataFailureIsWrapped() async throws {
        let apiProvider = ExpressAPIProviderStub()
        apiProvider.exchangeDataError = ExpressAPIError(code: 2264, value: nil)
        let sut = makeSUT(apiProvider: apiProvider, rateType: .fixed)

        do {
            _ = try await sut.sendData(currentState: .idle, request: makeRequest(amountType: .to(5), rateType: .fixed))
            Issue.record("Expected ExpressExchangeDataError")
        } catch let error as ExpressExchangeDataError {
            #expect(error.provider.id == "changehero")
            #expect(error.currencySymbol == "USDT")
            #expect(error.apiError?.code == 2264)
        }
    }

    @Test("With the toggle off, an exchange-data failure is passed on as it is")
    func exchangeDataFailureIsNotWrappedWithoutToggle() async {
        let apiProvider = ExpressAPIProviderStub()
        apiProvider.exchangeDataError = ExpressAPIError(code: 2264, value: nil)
        let sut = makeSUT(apiProvider: apiProvider, rateType: .fixed, isHideRejectedSwapProvidersEnabled: false)

        await #expect(throws: ExpressAPIError.self) {
            _ = try await sut.sendData(currentState: .idle, request: makeRequest(amountType: .to(5), rateType: .fixed))
        }
    }

    @Test("A request cancelled while in flight is not an exchange-data error")
    func cancelledRequestIsNotWrapped() async {
        let apiProvider = ExpressAPIProviderStub()
        apiProvider.exchangeDataError = URLError(.cancelled)
        apiProvider.cancelsCurrentTaskOnExchangeData = true
        let sut = makeSUT(apiProvider: apiProvider, rateType: .fixed)

        let task = Task {
            try await sut.sendData(currentState: .idle, request: makeRequest(amountType: .to(5), rateType: .fixed))
        }

        await #expect(throws: URLError.self) { try await task.value }
    }

    @Test("A fee estimation failure before the request is not an exchange-data error")
    func feeEstimationFailureIsNotWrapped() async throws {
        let sut = makeSUT(apiProvider: ExpressAPIProviderStub(), rateType: .float)

        await #expect(throws: StubError.self) {
            _ = try await sut.sendData(currentState: .idle, request: makeRequest(amountType: .from(5), rateType: .float))
        }
    }
}

// MARK: - Helpers

private extension CEXProviderFlowHelperExchangeDataErrorTests {
    func makeSUT(
        apiProvider: ExpressAPIProviderStub,
        rateType: ExpressProviderRateType,
        isHideRejectedSwapProvidersEnabled: Bool = true
    ) -> CEXProviderFlowHelper {
        CEXProviderFlowHelper(context: ExpressProviderFlowContext(
            provider: ExpressProvider(
                id: "changehero",
                name: "ChangeHero",
                type: .cex,
                exchangeOnlyWithinSingleAddress: false,
                imageURL: nil,
                termsOfUse: nil,
                privacyPolicy: nil,
                recommended: nil,
                slippage: nil,
                isCustomSlippageSupported: false
            ),
            pair: ExpressManagerSwappingPair(
                source: SourceWalletStub(analyticsLogger: AnalyticsLoggerSpy(), address: "0xOwner", allowanceProvider: nil),
                destination: DestinationWalletStub(currency: ExpressWalletCurrency(
                    contractAddress: "0xUSDT",
                    network: "ethereum",
                    decimalCount: 6,
                    symbol: "USDT"
                ))
            ),
            rateType: rateType,
            expressFeeProvider: FeeProviderFactoryStub().makeExpressFeeProvider(),
            expressAPIProvider: apiProvider,
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags(
                isSwapBestRateDefaultProviderEnabled: false,
                isHideRejectedSwapProvidersEnabled: isHideRejectedSwapProvidersEnabled
            )
        ))
    }

    func makeRequest(amountType: ExpressAmountType, rateType: ExpressProviderRateType) -> ExpressManagerSwappingPairRequest {
        ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: rateType,
            approvePolicy: .specified,
            operationType: .swap,
            slippage: nil,
            mcpIntentID: nil,
            quotesLoadingPerformanceTracker: nil
        )
    }
}
