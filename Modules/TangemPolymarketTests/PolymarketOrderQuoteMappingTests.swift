//
//  PolymarketOrderQuoteMappingTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("PolymarketOrderQuote mapping")
struct PolymarketOrderQuoteMappingTests {
    private let mapper = PolymarketMapper()

    @Test("Every figure of the quote arrives under its own name")
    func quoteIsMapped() throws {
        let quote = try mapper.mapOrderQuote(.stub())

        #expect(quote.status == .full)
        #expect(quote.side == .buy)
        #expect(quote.shares == Decimal(string: "97.95918"))
        #expect(quote.notional == 72)
        #expect(quote.expectedExecutionAmount == Decimal(string: "97.95918"))
        #expect(quote.averagePrice == Decimal(string: "0.72"))
        #expect(quote.worstCasePrice == Decimal(string: "0.735"))
        #expect(quote.fees.total == Decimal(string: "0.36"))
        #expect(quote.total == Decimal(string: "72.36"))
        #expect(quote.minOrderSize == 5)
        #expect(quote.minOrderAmount == 1)
        #expect(quote.tickSize == Decimal(string: "0.001"))
        #expect(quote.isLive)
    }

    @Test("A quote without the collateral floor keeps it absent rather than inventing one")
    func absentMinOrderAmountStaysAbsent() throws {
        let quote = try mapper.mapOrderQuote(.stub(minOrderAmount: nil))

        #expect(quote.minOrderAmount == nil)
    }

    @Test("A floor that is present but unreadable is reported, not quietly dropped")
    func unreadableMinOrderAmountIsRejected() {
        #expect(throws: PolymarketAPIError.self) {
            try mapper.mapOrderQuote(.stub(minOrderAmount: "one dollar"))
        }
    }

    @Test("An unreadable figure names the field it came from")
    func unreadableFigureNamesItsField() {
        do {
            _ = try mapper.mapOrderQuote(.stub(worstCasePrice: "n/a"))
            Issue.record("Expected the mapping to fail")
        } catch PolymarketAPIError.decoding(let field, let value) {
            #expect(field == "worstCasePrice")
            #expect(value == "n/a")
        } catch {
            Issue.record("Expected a decoding failure, got \(error)")
        }
    }

    @Test("An unknown side cannot be guessed, so the quote is refused")
    func unknownSideIsRejected() {
        #expect(throws: PolymarketAPIError.self) {
            try mapper.mapOrderQuote(.stub(side: "HOLD"))
        }
    }

    @Test("A status this build does not know is reported as undefined rather than as a closed market")
    func unknownStatusFallsBackToUndefined() throws {
        let quote = try mapper.mapOrderQuote(.stub(status: "SOMETHING_NEW"))

        #expect(quote.status == .undefined)
        #expect(!quote.status.isPlaceable)
    }

    @Test(
        "A builder code that is not thirty two bytes of hex is refused",
        arguments: ["", "0x", "abc", "0x00000000000000000000000000000000000000000000000000000000000000a", "0xzz00000000000000000000000000000000000000000000000000000000000000"]
    )
    func malformedBuilderCodeIsRejected(code: String) {
        #expect(throws: PolymarketAPIError.self) {
            try mapper.mapOrderQuote(.stub(builderCode: code))
        }
    }
}

// MARK: - Fixtures

private extension PolymarketDTO.OrderQuoteResponse {
    static func stub(
        status: String = "FULL",
        side: String = "BUY",
        worstCasePrice: String = "0.735",
        minOrderAmount: String? = "1",
        builderCode: String = "0x00000000000000000000000000000000000000000000000000000000000000aa"
    ) -> PolymarketDTO.OrderQuoteResponse {
        PolymarketDTO.OrderQuoteResponse(
            status: status,
            side: side,
            shares: "97.95918",
            notional: "72",
            expectedExecutionAmount: "97.95918",
            averagePrice: "0.72",
            worstCasePrice: worstCasePrice,
            fees: PolymarketDTO.OrderQuoteFees(market: "0.24", builder: "0.12", total: "0.36"),
            total: "72.36",
            builderCode: builderCode,
            minOrderSize: "5",
            minOrderAmount: minOrderAmount,
            tickSize: "0.001",
            live: true
        )
    }
}
