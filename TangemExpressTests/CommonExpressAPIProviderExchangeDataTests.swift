//
//  CommonExpressAPIProviderExchangeDataTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemExpress

@Suite("Express exchange data request — the addresses the backend is asked with")
struct CommonExpressAPIProviderExchangeDataTests {
    @Test("The destination becomes the payout address and the source the refund and sending address")
    func destinationIsPayoutAndSourceIsRefund() async {
        let service = ExpressAPIServiceSpy()
        let provider = CommonExpressAPIProvider(
            expressAPIService: service,
            expressAPIMapper: ExpressAPIMapper(
                exchangeDataDecoder: RefusingExchangeDataDecoderStub(),
                featureFlags: ExpressFeatureFlags(isRegionRestrictionsEnabled: false)
            )
        )

        _ = try? await provider.exchangeData(item: makeItem())

        let request = service.exchangeDataRequests.first

        #expect(service.exchangeDataRequests.count == 1)
        #expect(request?.toAddress == destinationAddress)
        #expect(request?.toExtraId == destinationExtraId)
        #expect(request?.refundAddress == sourceAddress)
        #expect(request?.fromAddress == sourceAddress)
    }
}

// MARK: - Fixtures

private extension CommonExpressAPIProviderExchangeDataTests {
    var sourceAddress: String { "0xSource" }
    var destinationAddress: String { "0xBridge" }
    var destinationExtraId: String { "memo" }

    func makeItem() -> ExpressSwappableDataItem {
        let source = ExpressWalletCurrency(contractAddress: "0xUSDT", network: "ethereum", decimalCount: 6, symbol: "USDT")
        let destination = ExpressWalletCurrency(contractAddress: "0xUSDC", network: "ethereum", decimalCount: 6, symbol: "USDC")
        let coin = ExpressWalletCurrency(contractAddress: "0x0", network: "ethereum", decimalCount: 18, symbol: "ETH")

        return ExpressSwappableDataItem(
            source: .init(address: sourceAddress, yieldContractAddress: nil, currency: source, coinCurrency: coin, amountScale: nil),
            destination: .init(address: destinationAddress, currency: destination, extraId: destinationExtraId),
            amountType: .from(1),
            rateType: .float,
            providerInfo: .init(id: "provider", type: .cex),
            operationType: .swap,
            quoteId: nil
        )
    }
}

// MARK: - Doubles

private struct RefusingExchangeDataDecoderStub: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        throw ServiceSpyError.notImplemented
    }
}

private final class ExpressAPIServiceSpy: ExpressAPIService {
    var exchangeDataRequests: [ExpressDTO.Swap.ExchangeData.Request] { requests.withLock { $0 } }

    private let requests = OSAllocatedUnfairLock(initialState: [ExpressDTO.Swap.ExchangeData.Request]())

    func exchangeData(request: ExpressDTO.Swap.ExchangeData.Request) async throws -> ExpressDTO.Swap.ExchangeData.Response {
        requests.withLock { $0.append(request) }

        return ExpressDTO.Swap.ExchangeData.Response(
            txId: "tx-1",
            fromAmount: "1000000",
            fromDecimals: 6,
            toAmount: "990000",
            toDecimals: 6,
            txDetailsJson: "{}",
            signature: "",
            payTill: nil
        )
    }

    func assets(request: ExpressDTO.Swap.Assets.Request) async throws -> [ExpressDTO.Swap.Assets.Response] { throw ServiceSpyError.notImplemented }
    func pairs(request: ExpressDTO.Swap.Pairs.Request) async throws -> [ExpressDTO.Swap.Pairs.Response] { throw ServiceSpyError.notImplemented }
    func providers() async throws -> [ExpressDTO.Swap.Providers.Response] { throw ServiceSpyError.notImplemented }
    func exchangeQuote(request: ExpressDTO.Swap.ExchangeQuote.Request) async throws -> ExpressDTO.Swap.ExchangeQuote.Response { throw ServiceSpyError.notImplemented }
    func exchangeStatus(request: ExpressDTO.Swap.ExchangeStatus.Request) async throws -> ExpressDTO.Swap.ExchangeStatus.Response { throw ServiceSpyError.notImplemented }
    func exchangeSent(request: ExpressDTO.Swap.ExchangeSent.Request) async throws -> ExpressDTO.Swap.ExchangeSent.Response { throw ServiceSpyError.notImplemented }
    func exchangeHistory(request: ExpressDTO.Swap.History.Request) async throws -> ExpressDTO.Swap.History.Response { throw ServiceSpyError.notImplemented }
    func exchangeHistoryDelta(request: ExpressDTO.Swap.HistoryDelta.Request) async throws -> ExpressDTO.Swap.HistoryDelta.Response { throw ServiceSpyError.notImplemented }
    func onrampCurrencies() async throws -> [ExpressDTO.Onramp.FiatCurrency] { throw ServiceSpyError.notImplemented }
    func onrampCountries() async throws -> [ExpressDTO.Onramp.Country] { throw ServiceSpyError.notImplemented }
    func onrampCountryByIP() async throws -> ExpressDTO.Onramp.Country { throw ServiceSpyError.notImplemented }
    func onrampPaymentMethods() async throws -> [ExpressDTO.Onramp.PaymentMethod] { throw ServiceSpyError.notImplemented }
    func onrampPairs(request: ExpressDTO.Onramp.Pairs.Request) async throws -> [ExpressDTO.Onramp.Pairs.Response] { throw ServiceSpyError.notImplemented }
    func onrampQuote(request: ExpressDTO.Onramp.Quote.Request) async throws -> ExpressDTO.Onramp.Quote.Response { throw ServiceSpyError.notImplemented }
    func onrampData(request: ExpressDTO.Onramp.Data.Request) async throws -> ExpressDTO.Onramp.Data.Response { throw ServiceSpyError.notImplemented }
    func onrampNativePaymentData(request: ExpressDTO.Onramp.NativePaymentData.Request) async throws -> ExpressDTO.Onramp.NativePaymentData.Response { throw ServiceSpyError.notImplemented }
    func onrampStatus(request: ExpressDTO.Onramp.Status.Request) async throws -> ExpressDTO.Onramp.Status.Response { throw ServiceSpyError.notImplemented }
    func onrampHistory(request: ExpressDTO.Onramp.History.Request) async throws -> ExpressDTO.Onramp.History.Response { throw ServiceSpyError.notImplemented }
    func onrampHistoryDelta(request: ExpressDTO.Onramp.HistoryDelta.Request) async throws -> ExpressDTO.Onramp.HistoryDelta.Response { throw ServiceSpyError.notImplemented }
}

private enum ServiceSpyError: Error {
    case notImplemented
}
