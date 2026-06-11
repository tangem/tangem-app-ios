//
//  ExpressAPIMapperHistoryTests.swift
//  TangemExpressTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemExpress

@Suite("Express history DTO decoding and mapping — exchange/onramp records and pagination")
struct ExpressAPIMapperHistoryTests {
    private let mapper = ExpressAPIMapper(exchangeDataDecoder: StubExpressExchangeDataDecoder())

    /// Same configuration as the decoder in `CommonExpressAPIService`.
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()

    // MARK: - Exchange

    @Test("Exchange history response decodes and maps records, cursors, and `hasMore`")
    func exchangeHistoryResponseMapping() throws {
        let response = try decoder.decode(
            ExpressDTO.Swap.History.Response.self,
            from: Data(Self.exchangeHistoryResponseJSON.utf8)
        )
        let page = try mapper.mapToExchangeHistoryPage(response: response)

        #expect(page.hasMore)
        #expect(page.nextCursor as? String == "cursor-end")
        #expect(page.startDeltaCursor as? String == "cursor-delta")
        #expect(page.records.count == 2)

        let full = try #require(page.records.first)
        #expect(full.txId == "tx-1")
        #expect(full.providerId == "changenow")
        #expect(full.status == .finished)
        #expect(full.rateType == .float)
        #expect(full.fromAddress == "0xfrom")
        #expect(full.payIn == PayInInfo(address: "0xpayin", extraId: "memo-in", hash: "0xhash-in"))
        #expect(full.payOut == PayOutInfo(address: "0xpayout", hash: "0xhash-out"))
        #expect(full.externalTx?.id == "ext-1")
        #expect(full.refund?.address == "0xrefund")
        #expect(full.refund?.currency == ExpressCurrency(contractAddress: "0xrefund-token", network: "ethereum"))
        #expect(full.from.amount == Decimal(stringValue: "1.5"))
        #expect(full.to.amount == Decimal(stringValue: "1"))
        #expect(full.to.actualAmount == Decimal(stringValue: "0.99"))
        #expect(full.createdAt < full.updatedAt)

        let minimal = try #require(page.records.last)
        #expect(minimal.status == .exchangeTxSent)
        #expect(minimal.fromAddress == nil)
        #expect(minimal.externalTx == nil)
        #expect(minimal.refund == nil)
    }

    @Test("Exchange history pagination without the required `hasMore` field fails to decode")
    func exchangeHistoryPaginationRequiresHasMore() throws {
        #expect(throws: (any Error).self) {
            try decoder.decode(
                ExpressDTO.Swap.History.Response.self,
                from: Data(Self.exchangeHistoryResponseWithoutHasMoreJSON.utf8)
            )
        }
    }

    // MARK: - Onramp

    @Test("Onramp history response decodes the onramp-shaped record and maps amounts by precision/decimals")
    func onrampHistoryResponseMapping() throws {
        let response = try decoder.decode(
            ExpressDTO.Onramp.History.Response.self,
            from: Data(Self.onrampHistoryResponseJSON.utf8)
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
        #expect(pending.payOut == PayOutInfo(address: "0xpayout-1", hash: nil))
        #expect(pending.from == OnrampHistoryFiatAsset(currencyCode: "EUR", amount: Decimal(stringValue: "100.5")!))
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
        #expect(finished.to.amount == Decimal(stringValue: "2"))
        #expect(finished.to.actualAmount == Decimal(stringValue: "1.99"))
    }

    @Test("Unrecognized onramp history status raw values fall back to `.unknown`")
    func onrampHistoryUnknownStatusFallback() throws {
        let json = Self.onrampHistoryResponseJSON.replacingOccurrences(of: "waiting-for-payment", with: "exchange-tx-sent")
        let response = try decoder.decode(ExpressDTO.Onramp.History.Response.self, from: Data(json.utf8))
        let page = try mapper.mapToOnrampHistoryPage(response: response)

        #expect(page.records.first?.status == .unknown)
    }

    @Test("Onramp history delta response maps `startCursor` into the next-page cursor")
    func onrampHistoryDeltaResponseMapping() throws {
        let response = try decoder.decode(
            ExpressDTO.Onramp.HistoryDelta.Response.self,
            from: Data(Self.onrampHistoryDeltaResponseJSON.utf8)
        )
        let page = try mapper.mapToOnrampHistoryPage(response: response)

        #expect(page.records.isEmpty)
        #expect(page.nextCursor as? String == "cursor-start")
        #expect(page.startDeltaCursor == nil)
        #expect(!page.hasMore)
    }
}

// MARK: - Fixtures

private extension ExpressAPIMapperHistoryTests {
    static let exchangeHistoryResponseJSON = """
    {
        "items": [
            {
                "txId": "tx-1",
                "providerId": "changenow",
                "fromAddress": "0xfrom",
                "payinAddress": "0xpayin",
                "payinExtraId": "memo-in",
                "payoutAddress": "0xpayout",
                "refundAddress": "0xrefund",
                "refundExtraId": "memo-refund",
                "rateType": "float",
                "status": "finished",
                "externalTxId": "ext-1",
                "externalTxStatus": "finished",
                "externalTxUrl": "https://provider.example/tx/ext-1",
                "payinHash": "0xhash-in",
                "payoutHash": "0xhash-out",
                "refundNetwork": "ethereum",
                "refundContractAddress": "0xrefund-token",
                "createdAt": "2026-06-01T10:00:00.000+0000",
                "updatedAt": "2026-06-01T10:05:00.000+0000",
                "payTill": "2026-06-01T10:30:00.000+0000",
                "averageDuration": 600,
                "fromContractAddress": "0x0",
                "fromNetwork": "ethereum",
                "fromDecimals": 6,
                "fromAmount": "1500000",
                "toContractAddress": "0x0",
                "toNetwork": "bitcoin",
                "toDecimals": 8,
                "toAmount": "100000000",
                "toActualAmount": "99000000"
            },
            {
                "txId": "tx-2",
                "providerId": "okx",
                "payinAddress": "0xpayin-2",
                "payoutAddress": "0xpayout-2",
                "rateType": "fixed",
                "status": "exchange-tx-sent",
                "createdAt": "2026-06-02T10:00:00.000+0000",
                "updatedAt": "2026-06-02T10:05:00.000+0000",
                "fromContractAddress": "0x0",
                "fromNetwork": "ethereum",
                "fromDecimals": 18,
                "fromAmount": "1000000000000000000",
                "toContractAddress": "0x0",
                "toNetwork": "polygon",
                "toDecimals": 18,
                "toAmount": "2000000000000000000"
            }
        ],
        "pagination": {
            "endCursor": "cursor-end",
            "startDeltaCursor": "cursor-delta",
            "hasMore": true
        }
    }
    """

    static let exchangeHistoryResponseWithoutHasMoreJSON = """
    {
        "items": [],
        "pagination": {
            "endCursor": null,
            "startDeltaCursor": null
        }
    }
    """

    static let onrampHistoryResponseJSON = """
    {
        "items": [
            {
                "txId": "tx-onramp-1",
                "providerId": "mercuryo",
                "payoutAddress": "0xpayout-1",
                "status": "waiting-for-payment",
                "createdAt": "2026-06-01T10:00:00.000+0000",
                "updatedAt": "2026-06-01T10:05:00.000+0000",
                "fromCurrencyCode": "EUR",
                "fromAmount": "10050",
                "fromPrecision": 2,
                "toContractAddress": "0x0",
                "toNetwork": "ethereum",
                "toDecimals": 18,
                "paymentMethod": "card",
                "countryCode": "DE"
            },
            {
                "txId": "tx-onramp-2",
                "providerId": "moonpay",
                "payoutAddress": "0xpayout-2",
                "status": "finished",
                "failReason": "kyc_failed",
                "externalTxId": "ext-2",
                "externalTxUrl": "https://provider.example/tx/ext-2",
                "payoutHash": "0xhash-out",
                "createdAt": "2026-06-02T10:00:00.000+0000",
                "updatedAt": "2026-06-02T10:05:00.000+0000",
                "fromCurrencyCode": "USD",
                "fromAmount": "50000",
                "fromPrecision": 2,
                "toContractAddress": "0x0",
                "toNetwork": "ethereum",
                "toDecimals": 18,
                "toAmount": "2000000000000000000",
                "toActualAmount": "1990000000000000000",
                "paymentMethod": "apple-pay",
                "countryCode": "US"
            }
        ],
        "pagination": {
            "endCursor": "cursor-end",
            "startDeltaCursor": null,
            "hasMore": false
        }
    }
    """

    static let onrampHistoryDeltaResponseJSON = """
    {
        "items": [],
        "pagination": {
            "startCursor": "cursor-start",
            "hasMore": false
        }
    }
    """
}

// MARK: - Stubs

private struct StubExpressExchangeDataDecoder: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        fatalError("Not used in tests")
    }
}
