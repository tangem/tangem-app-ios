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

    @Test("A sale nets its total off the expectation rather than the guarantee")
    func sellTotalNetsOffTheExpectation() throws {
        let quote = try mapper.mapOrderQuote(.sellStub())

        #expect(quote.side == .sell)
        #expect(quote.shares == Decimal(string: "100.00"))
        #expect(quote.notional == Decimal(string: "68.60000"))
        #expect(quote.expectedExecutionAmount == Decimal(string: "70.00000"))
        #expect(quote.total == Decimal(string: "67.20000"))
        #expect(quote.total == quote.expectedExecutionAmount - quote.fees.total)
    }

    @Test("A sale at the widest tolerance keeps the total it had at the narrowest")
    func sellTotalSurvivesACollapsedGuarantee() throws {
        let narrow = try mapper.mapOrderQuote(.sellStub())
        let wide = try mapper.mapOrderQuote(.sellStub(notional: "0.10000", worstCasePrice: "0.001"))

        #expect(wide.notional == Decimal(string: "0.10000"))
        #expect(wide.expectedExecutionAmount == narrow.expectedExecutionAmount)
        #expect(wide.total == narrow.total)
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

// MARK: - Signing domain

extension PolymarketOrderQuoteMappingTests {
    @Test("A V2 quote carries ExchangeV3 and domain version 3")
    func v2QuoteCarriesItsDomain() throws {
        let quote = try mapper.mapOrderQuote(
            .stub(version: "v2", exchange: "0xe3333700cA9d93003F00f0F71f8515005F6c00Aa", signingDomainVersion: "3")
        )

        #expect(quote.version == .v2)
        #expect(quote.exchange == "0xe3333700cA9d93003F00f0F71f8515005F6c00Aa")
        #expect(quote.signingDomainVersion == "3")
        #expect(try PolymarketExchange.domain(for: quote, isNegRisk: true) == .exchangeV3)
    }

    @Test("A V1 quote keeps the exchange the market's risk mode picks")
    func v1QuoteCarriesItsDomain() throws {
        let quote = try mapper.mapOrderQuote(.stub())

        #expect(quote.version == .v1)
        #expect(try PolymarketExchange.domain(for: quote, isNegRisk: false) == .ctfExchange)
        #expect(throws: PolymarketExchangeDomainError.self) {
            try PolymarketExchange.domain(for: quote, isNegRisk: true)
        }
    }

    @Test("A quote for a market of unknown version decodes, with nothing to sign for")
    func unknownVersionQuoteDecodes() throws {
        let quote = try mapper.mapOrderQuote(
            .stub(status: "MARKET_CLOSED", version: "unknown", exchange: nil, signingDomainVersion: nil)
        )

        #expect(quote.version == .unknown("unknown"))
        #expect(quote.exchange == nil)
        #expect(quote.signingDomainVersion == nil)
        #expect(throws: PolymarketExchangeDomainError.unsupportedVersion(.unknown("unknown"))) {
            try PolymarketExchange.domain(for: quote, isNegRisk: false)
        }
    }

    @Test("A quote without the new fields still decodes and is never signed")
    func quoteWithoutVersionDecodes() throws {
        let json = """
        {
          "status": "FULL", "side": "BUY", "shares": "1", "notional": "1", "expectedExecutionAmount": "1",
          "averagePrice": "0.5", "worstCasePrice": "0.5",
          "fees": { "market": "0", "builder": "0", "total": "0" },
          "total": "1", "builderCode": "0x00000000000000000000000000000000000000000000000000000000000000aa",
          "minOrderSize": "5", "tickSize": "0.01", "live": false
        }
        """

        let dto = try JSONDecoder().decode(PolymarketDTO.OrderQuoteResponse.self, from: Data(json.utf8))
        let quote = try mapper.mapOrderQuote(dto)

        #expect(quote.version == .unknown(nil))
        #expect(throws: PolymarketExchangeDomainError.self) {
            try PolymarketExchange.domain(for: quote, isNegRisk: false)
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
        builderCode: String = "0x00000000000000000000000000000000000000000000000000000000000000aa",
        version: String? = "v1",
        exchange: String? = "0xE111180000d2663C0091e4f400237545B87B996B",
        signingDomainVersion: String? = "2"
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
            live: true,
            version: version,
            exchange: exchange,
            signingDomainVersion: signingDomainVersion
        )
    }

    static func sellStub(
        notional: String = "68.60000",
        worstCasePrice: String = "0.686"
    ) -> PolymarketDTO.OrderQuoteResponse {
        PolymarketDTO.OrderQuoteResponse(
            status: "FULL",
            side: "SELL",
            shares: "100.00",
            notional: notional,
            expectedExecutionAmount: "70.00000",
            averagePrice: "0.700",
            worstCasePrice: worstCasePrice,
            fees: PolymarketDTO.OrderQuoteFees(market: "1.05000", builder: "1.75000", total: "2.80000"),
            total: "67.20000",
            builderCode: "0x00000000000000000000000000000000000000000000000000000000000000aa",
            minOrderSize: "7",
            minOrderAmount: "1",
            tickSize: "0.001",
            live: false,
            version: "v1",
            exchange: "0xE111180000d2663C0091e4f400237545B87B996B",
            signingDomainVersion: "2"
        )
    }
}
