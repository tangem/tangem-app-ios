//
//  ExpressManagerMapperTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("Express manager mapper — the pair's addresses become the data item's")
struct ExpressManagerMapperTests {
    private let mapper = ExpressManagerMapper()

    @Test("The destination's address and extra id and the source's address travel into the data item unchanged")
    func addressesTravelUnchanged() throws {
        let pair = makePair(
            sourceAddress: "0xSource",
            destination: DestinationWalletStub(address: "0xBridge", extraId: "memo", currency: destinationCurrency)
        )

        let item = try mapper.makeExpressSwappableDataItem(pair: pair, request: makeRequest(), providerId: "provider", providerType: .dex)

        #expect(item.source.address == "0xSource")
        #expect(item.destination.address == "0xBridge")
        #expect(item.destination.extraId == "memo")
        #expect(item.destination.currency == destinationCurrency)
        #expect(item.source.currency != destinationCurrency)
    }

    @Test("The request slippage travels into the quote and data items")
    func slippageTravelsIntoItems() throws {
        let pair = makePair(sourceAddress: "0xSource", destination: DestinationWalletStub(currency: destinationCurrency))
        let request = makeRequest(slippage: Decimal(string: "0.01"))

        let quoteItem = mapper.makeExpressSwappableItem(pair: pair, request: request, providerId: "provider", providerType: .dex)
        let dataItem = try mapper.makeExpressSwappableDataItem(pair: pair, request: request, providerId: "provider", providerType: .dex)

        #expect(quoteItem.slippage == Decimal(string: "0.01"))
        #expect(dataItem.slippage == Decimal(string: "0.01"))
    }

    @Test("A destination without an address cannot become a data item")
    func destinationWithoutAddressIsRefused() {
        let pair = makePair(sourceAddress: "0xSource", destination: DestinationWalletStub(address: nil))

        do {
            _ = try mapper.makeExpressSwappableDataItem(pair: pair, request: makeRequest(), providerId: "provider", providerType: .dex)
            Issue.record("A destination without an address was accepted")
        } catch ExpressManagerMapper.Error.destinationAddressNotFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("A source without an address cannot become a data item")
    func sourceWithoutAddressIsRefused() {
        let pair = makePair(sourceAddress: nil, destination: DestinationWalletStub(address: "0xBridge"))

        do {
            _ = try mapper.makeExpressSwappableDataItem(pair: pair, request: makeRequest(), providerId: "provider", providerType: .dex)
            Issue.record("A source without an address was accepted")
        } catch ExpressManagerMapper.Error.sourceAddressNotFound {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

// MARK: - Fixtures

private extension ExpressManagerMapperTests {
    var destinationCurrency: ExpressWalletCurrency {
        ExpressWalletCurrency(contractAddress: "0xUSDC", network: "polygon", decimalCount: 6, symbol: "USDC")
    }

    func makePair(sourceAddress: String?, destination: DestinationWalletStub) -> ExpressManagerSwappingPair {
        ExpressManagerSwappingPair(
            source: SourceWalletStub(analyticsLogger: AnalyticsLoggerSpy(), address: sourceAddress, allowanceProvider: nil),
            destination: destination
        )
    }

    func makeRequest(slippage: Decimal? = nil) -> ExpressManagerSwappingPairRequest {
        ExpressManagerSwappingPairRequest(
            amountType: .from(1),
            rateType: .float,
            approvePolicy: .specified,
            operationType: .swap,
            slippage: slippage,
            quotesLoadingPerformanceTracker: nil
        )
    }
}
