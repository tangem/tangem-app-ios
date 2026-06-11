//
//  ExpressAPIMapperHistoryTests.swift
//  TangemExpressTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import AnyCodable
import TangemFoundation
@testable import TangemExpress

@Suite("Express history mapping — exchange/onramp records and pagination")
struct ExpressAPIMapperHistoryTests {
    private let mapper = ExpressAPIMapper(exchangeDataDecoder: StubExpressExchangeDataDecoder())

    // MARK: - Exchange

    @Test("Exchange history page maps records, opaque cursors, and `hasMore`")
    func exchangeHistoryPageMapping() throws {
        let response = ExpressDTO.Swap.History.Response(
            items: [Self.makeExchangeRecord()],
            pagination: ExpressDTO.Swap.History.Pagination(
                endCursor: AnyDecodable("cursor-end"),
                startDeltaCursor: AnyDecodable("cursor-delta"),
                hasMore: true
            )
        )

        let page = try mapper.mapToExchangeHistoryPage(response: response)

        #expect(page.hasMore)
        #expect(page.nextCursor as? String == "cursor-end")
        #expect(page.startDeltaCursor as? String == "cursor-delta")

        let record = try #require(page.records.first)
        #expect(record.txId == "tx-1")
        #expect(record.providerId == "changenow")
        #expect(record.status == .finished)
        #expect(record.rateType == .float)
        #expect(record.fromAddress == "0xfrom")
        #expect(record.payIn == PayInInfo(address: "0xpayin", extraId: "memo-in", hash: "0xhash-in"))
        #expect(record.payOut == PayOutInfo(address: "0xpayout", hash: "0xhash-out"))
        #expect(record.externalTx?.id == "ext-1")
        #expect(record.refund?.address == "0xrefund")
        #expect(record.refund?.currency == ExpressCurrency(contractAddress: "0xrefund-token", network: "ethereum"))
        #expect(try record.from.amount == #require(Decimal(stringValue: "1.5")))
        #expect(try record.to.amount == #require(Decimal(stringValue: "1")))
        #expect(try record.to.actualAmount == #require(Decimal(stringValue: "0.99")))
        #expect(record.createdAt < record.updatedAt)
    }

    @Test("Exchange record without optional fields maps them to nil, unknown status falls back to `.unknown`")
    func exchangeRecordOptionalFieldsAndUnknownStatus() throws {
        let response = ExpressDTO.Swap.History.Response(
            items: [
                Self.makeExchangeRecord(
                    fromAddress: nil,
                    refundAddress: nil,
                    refundContractAddress: nil,
                    status: "some-future-status",
                    externalTxId: nil
                ),
            ],
            pagination: ExpressDTO.Swap.History.Pagination(endCursor: nil, startDeltaCursor: nil, hasMore: false)
        )

        let page = try mapper.mapToExchangeHistoryPage(response: response)

        let record = try #require(page.records.first)
        #expect(record.status == .unknown)
        #expect(record.fromAddress == nil)
        #expect(record.externalTx == nil)
        #expect(record.refund == nil)
        #expect(!page.hasMore)
        #expect(page.nextCursor == nil)
    }

    // MARK: - Onramp

    @Test("Onramp history page maps the onramp-shaped record, converting amounts by precision/decimals")
    func onrampHistoryPageMapping() throws {
        let response = ExpressDTO.Onramp.History.Response(
            items: [
                Self.makeOnrampRecord(),
                Self.makeOnrampRecord(
                    status: "finished",
                    failReason: "kyc_failed",
                    externalTxId: "ext-2",
                    payoutHash: "0xhash-out",
                    toAmount: "2000000000000000000",
                    toActualAmount: "1990000000000000000"
                ),
            ],
            pagination: ExpressDTO.Onramp.History.Pagination(
                endCursor: AnyDecodable("cursor-end"),
                startDeltaCursor: nil,
                hasMore: false
            )
        )

        let page = try mapper.mapToOnrampHistoryPage(response: response)

        #expect(!page.hasMore)
        #expect(page.records.count == 2)

        let pending = try #require(page.records.first)
        #expect(pending.txId == "tx-onramp-1")
        #expect(pending.providerId == "mercuryo")
        #expect(pending.status == .waitingForPayment)
        #expect(pending.failReason == nil)
        #expect(pending.externalTx == nil)
        #expect(pending.payOut == PayOutInfo(address: "0xpayout", hash: nil))
        #expect(try pending.from == OnrampHistoryFiatAsset(currencyCode: "EUR", amount: #require(Decimal(stringValue: "100.5"))))
        #expect(pending.to.currency == ExpressCurrency(contractAddress: "0x0", network: "ethereum"))
        #expect(pending.to.amount == nil)
        #expect(pending.to.actualAmount == nil)
        #expect(pending.paymentMethod == "card")
        #expect(pending.countryCode == "DE")

        let finished = try #require(page.records.last)
        #expect(finished.status == .finished)
        #expect(finished.failReason == "kyc_failed")
        #expect(finished.externalTx?.id == "ext-2")
        #expect(finished.payOut.hash == "0xhash-out")
        #expect(try finished.to.amount == #require(Decimal(stringValue: "2")))
        #expect(try finished.to.actualAmount == #require(Decimal(stringValue: "1.99")))
    }

    @Test("Unrecognized onramp status raw values fall back to `.unknown`")
    func onrampUnknownStatusFallback() throws {
        let response = ExpressDTO.Onramp.History.Response(
            items: [Self.makeOnrampRecord(status: "exchange-tx-sent")],
            pagination: ExpressDTO.Onramp.History.Pagination(endCursor: nil, startDeltaCursor: nil, hasMore: false)
        )

        let page = try mapper.mapToOnrampHistoryPage(response: response)

        #expect(page.records.first?.status == .unknown)
    }

    @Test("Onramp history delta page maps `startCursor` into the next-page cursor")
    func onrampHistoryDeltaPageMapping() throws {
        let response = ExpressDTO.Onramp.HistoryDelta.Response(
            items: [],
            pagination: ExpressDTO.Onramp.HistoryDelta.Pagination(startCursor: AnyDecodable("cursor-start"), hasMore: false)
        )

        let page = try mapper.mapToOnrampHistoryPage(response: response)

        #expect(page.records.isEmpty)
        #expect(page.nextCursor as? String == "cursor-start")
        #expect(page.startDeltaCursor == nil)
        #expect(!page.hasMore)
    }

    @Test("Malformed decimal amount in a record fails the whole page mapping")
    func malformedDecimalAmountThrows() throws {
        let response = ExpressDTO.Onramp.History.Response(
            items: [Self.makeOnrampRecord(toAmount: "not-a-decimal")],
            pagination: ExpressDTO.Onramp.History.Pagination(endCursor: nil, startDeltaCursor: nil, hasMore: false)
        )

        #expect(throws: (any Error).self) {
            try mapper.mapToOnrampHistoryPage(response: response)
        }
    }
}

// MARK: - Factories

private extension ExpressAPIMapperHistoryTests {
    static func makeExchangeRecord(
        fromAddress: String? = "0xfrom",
        refundAddress: String? = "0xrefund",
        refundContractAddress: String? = "0xrefund-token",
        status: String = "finished",
        externalTxId: String? = "ext-1"
    ) -> ExpressDTO.Swap.History.Record {
        ExpressDTO.Swap.History.Record(
            txId: "tx-1",
            providerId: "changenow",
            fromAddress: fromAddress,
            payinAddress: "0xpayin",
            payinExtraId: "memo-in",
            payoutAddress: "0xpayout",
            refundAddress: refundAddress,
            refundExtraId: "memo-refund",
            rateType: "float",
            status: status,
            externalTxId: externalTxId,
            externalTxUrl: "https://provider.example/tx/ext-1",
            payinHash: "0xhash-in",
            payoutHash: "0xhash-out",
            refundNetwork: "ethereum",
            refundContractAddress: refundContractAddress,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000),
            payTill: nil,
            averageDuration: 600,
            fromContractAddress: "0x0",
            fromNetwork: "ethereum",
            fromDecimals: 6,
            fromAmount: "1500000",
            toContractAddress: "0x0",
            toNetwork: "bitcoin",
            toDecimals: 8,
            toAmount: "100000000",
            toActualAmount: "99000000"
        )
    }

    static func makeOnrampRecord(
        status: String = "waiting-for-payment",
        failReason: String? = nil,
        externalTxId: String? = nil,
        payoutHash: String? = nil,
        toAmount: String? = nil,
        toActualAmount: String? = nil
    ) -> ExpressDTO.Onramp.History.Record {
        ExpressDTO.Onramp.History.Record(
            txId: "tx-onramp-1",
            providerId: "mercuryo",
            payoutAddress: "0xpayout",
            status: status,
            failReason: failReason,
            externalTxId: externalTxId,
            externalTxUrl: nil,
            payoutHash: payoutHash,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000),
            fromCurrencyCode: "EUR",
            fromAmount: "10050",
            fromPrecision: 2,
            toContractAddress: "0x0",
            toNetwork: "ethereum",
            toDecimals: 18,
            toAmount: toAmount,
            toActualAmount: toActualAmount,
            paymentMethod: "card",
            countryCode: "DE"
        )
    }
}

// MARK: - Stubs

private struct StubExpressExchangeDataDecoder: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        fatalError("Not used in tests")
    }
}
