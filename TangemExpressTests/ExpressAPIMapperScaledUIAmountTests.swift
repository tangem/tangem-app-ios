//
//  ExpressAPIMapperScaledUIAmountTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("Express amount mapping for tokens with a scaled UI amount configuration")
struct ExpressAPIMapperScaledUIAmountTests {
    private let mapper = ExpressAPIMapper(
        exchangeDataDecoder: StubExchangeDataDecoder(),
        featureFlags: ExpressFeatureFlags(isRegionRestrictionsEnabled: false)
    )

    @Test("A CEX txValue is mapped into displayed space, matching what the chain expects to unscale")
    func cexTxValueIsMappedIntoDisplayedSpace() throws {
        let item = Self.makeItem(scale: 2)

        // 5 on-chain tokens, which the user sees as 10 because the mint scales by 2.
        let value = try mapper.mapTxValueToDecimalValue(item: item, txValue: "5000000", txType: .send)

        #expect(value == 10)
    }

    @Test("The source amount sent to the API and the txValue read back describe the same transfer")
    func sourceAmountAndTxValueRoundTrip() throws {
        let item = Self.makeItem(scale: 2, amount: 10)

        let sentWEI = try #require(try item.sourceAmountWEI())
        let value = try mapper.mapTxValueToDecimalValue(item: item, txValue: sentWEI, txType: .send)

        #expect(value == item.amount)
    }

    @Test("An unscaled token leaves the CEX txValue as the plain on-chain amount")
    func cexTxValueIsUntouchedWithoutScaling() throws {
        let item = Self.makeItem(scale: nil)

        let value = try mapper.mapTxValueToDecimalValue(item: item, txValue: "5000000", txType: .send)

        #expect(value == 5)
    }

    @Test("A DEX txValue stays in coin space, which scaling never applies to")
    func dexTxValueIsNotScaled() throws {
        let item = Self.makeItem(scale: 2)

        let value = try mapper.mapTxValueToDecimalValue(item: item, txValue: "1000000000", txType: .swap)

        #expect(value == 1)
    }
}

// MARK: - Factories

private extension ExpressAPIMapperScaledUIAmountTests {
    static func makeItem(scale: Decimal?, amount: Decimal = 10) -> ExpressSwappableDataItem {
        ExpressSwappableDataItem(
            source: ExpressSwappableDataItem.SourceWalletInfo(
                address: "source-address",
                yieldContractAddress: nil,
                currency: ExpressWalletCurrency(contractAddress: "mint", network: "solana", decimalCount: 6, symbol: "TKN"),
                coinCurrency: ExpressWalletCurrency(contractAddress: "0x0", network: "solana", decimalCount: 9, symbol: "SOL"),
                amountScale: scale
            ),
            destination: ExpressSwappableDataItem.DestinationWalletInfo(
                address: "destination-address",
                currency: ExpressWalletCurrency(contractAddress: "0x0", network: "bitcoin", decimalCount: 8, symbol: "BTC"),
                extraId: nil
            ),
            amountType: .from(amount),
            rateType: .float,
            providerInfo: ExpressSwappableDataItem.ProviderInfo(id: "changenow", type: .cex),
            operationType: .swap,
            quoteId: nil
        )
    }
}

// MARK: - Stubs

private struct StubExchangeDataDecoder: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        fatalError("Not used in tests")
    }
}
