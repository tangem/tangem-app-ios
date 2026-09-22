//
//  PolymarketOrderPlacementTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("PolymarketOrderFactory")
struct PolymarketOrderFactoryTests {
    @Test("A buy commits the typed USDC and receives the guaranteed shares")
    func buyLegs() {
        let order = PolymarketOrderFactory.make(
            quote: .stub(side: .buy, notional: 72, shares: Decimal(string: "97.95918")!),
            assetId: "1116017998421700000000000000000000000000000000000000000000000000047",
            depositWalletAddress: Self.depositWallet
        )

        #expect(order.makerAmount == "72000000")
        #expect(order.takerAmount == "97959180")
    }

    @Test("A sell places the typed shares and receives the guaranteed USDC")
    func sellLegs() {
        let order = PolymarketOrderFactory.make(
            quote: .stub(side: .sell, notional: Decimal(string: "68.6")!, shares: 100),
            assetId: "47",
            depositWalletAddress: Self.depositWallet
        )

        #expect(order.makerAmount == "100000000")
        #expect(order.takerAmount == "68600000")
    }

    @Test("A leg finer than the collateral grid is truncated, never rounded up")
    func legsAreTruncated() {
        let order = PolymarketOrderFactory.make(
            quote: .stub(side: .buy, notional: 72, shares: Decimal(string: "97.9591899999")!),
            assetId: "47",
            depositWalletAddress: Self.depositWallet
        )

        #expect(order.takerAmount == "97959189")
    }

    @Test("The order is signed by the deposit wallet on its own behalf")
    func makerAndSignerAreTheDepositWallet() {
        let order = PolymarketOrderFactory.make(
            quote: .stub(side: .buy, notional: 1, shares: 1),
            assetId: "47",
            depositWalletAddress: Self.depositWallet
        )

        #expect(order.maker == Self.depositWallet)
        #expect(order.signer == Self.depositWallet)
        #expect(order.signatureType == PolymarketExchange.depositWalletSignatureType)
    }

    @Test("The builder code is carried from the quote that priced the order")
    func builderComesFromTheQuote() {
        let order = PolymarketOrderFactory.make(
            quote: .stub(side: .buy, notional: 1, shares: 1),
            assetId: "47",
            depositWalletAddress: Self.depositWallet
        )

        #expect(order.builder == PolymarketOrderQuote.stubBuilderCode)
        #expect(order.metadata == PolymarketExchange.emptyWord)
    }

    @Test("The salt stays inside the range a JSON number carries exactly")
    func saltIsSafeForJSON() {
        for _ in 0 ..< 128 {
            let order = PolymarketOrderFactory.make(
                quote: .stub(side: .buy, notional: 1, shares: 1),
                assetId: "47",
                depositWalletAddress: Self.depositWallet
            )

            #expect(order.salt >= 1)
            #expect(order.salt <= 9_007_199_254_740_991)
        }
    }
}

// MARK: - Wire format

@Suite("PolymarketPlaceOrder wire format")
struct PolymarketPlaceOrderWireFormatTests {
    @Test("The request states every field under the name the exchange reads")
    func requestFieldNames() throws {
        let body = PolymarketMapper().mapPlaceOrderRequest(Self.signedOrder, apiKey: "api-key")
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: Any]

        let order = try #require(json?["order"] as? [String: Any])

        #expect(json?["owner"] as? String == "api-key")
        #expect(json?["orderType"] as? String == "FAK")
        #expect(json?["postOnly"] as? Bool == false)
        #expect(json?["deferExec"] as? Bool == false)

        #expect(order["salt"] as? UInt64 == 1_234_567_890)
        #expect(order["maker"] as? String == "0x5a057dc6394196fba51d84457da3fb8fa241fc20")
        #expect(order["signer"] as? String == "0x4130efa9e628a991520be60f2e948a4f9be52fbc")
        #expect(order["tokenId"] as? String == "47")
        #expect(order["makerAmount"] as? String == "72000000")
        #expect(order["takerAmount"] as? String == "97959180")
        #expect(order["side"] as? String == "BUY")
        #expect(order["signatureType"] as? Int == 3)
        #expect(order["timestamp"] as? String == "1787300000000")
        #expect(order["expiration"] as? String == "0")
        #expect(order["signature"] as? String == "0xdeadbeef")
    }

    @Test("The addresses go out lowercased, the way the exchange stores them")
    func addressesAreLowercased() throws {
        let body = PolymarketMapper().mapPlaceOrderRequest(Self.signedOrder, apiKey: "api-key")

        #expect(body.order.maker == body.order.maker.lowercased())
        #expect(body.order.signer == body.order.signer.lowercased())
    }

    @Test("The exchange's own answer is read under its wire names")
    func responseIsDecoded() throws {
        let json = """
        {"errorMsg":"","orderID":"0xf1503cb4","takingAmount":"7.692306","makingAmount":"0.999999",
        "status":"matched","transactionsHashes":["0x7365a3d2"],"success":true}
        """

        let dto = try JSONDecoder().decode(PolymarketDTO.PlaceOrderResponse.self, from: Data(json.utf8))
        let placement = PolymarketMapper().mapPlaceOrder(dto)

        #expect(dto.success)
        #expect(placement.orderId == "0xf1503cb4")
        #expect(placement.status == .matched)
        #expect(placement.makingAmount == Decimal(string: "0.999999"))
        #expect(placement.takingAmount == Decimal(string: "7.692306"))
        #expect(placement.transactionHashes == ["0x7365a3d2"])
    }

    @Test("A book with nothing to match is a refusal of its own, not a transport failure")
    func unmatchedFillAndKillIsRecognised() {
        let detail = PolymarketProblemDetail(
            type: nil,
            title: nil,
            status: 400,
            detail: "no orders found to match with FAK order",
            instance: nil
        )

        let error = CommonPolymarketCLOBService.placementError(from: .http(statusCode: 400, problemDetail: detail))

        guard case .noLiquidity(let message) = error else {
            Issue.record("Expected a no-liquidity refusal, got \(error)")
            return
        }

        #expect(message == detail.detail)
    }

    @Test("A refusal the exchange spelled out is final, not ambiguous")
    func spelledOutRefusalIsFinal() {
        let detail = PolymarketProblemDetail(
            type: nil,
            title: nil,
            status: 400,
            detail: "not enough balance",
            instance: nil
        )

        let error = CommonPolymarketCLOBService.placementError(from: .http(statusCode: 400, problemDetail: detail))

        #expect(!error.isAmbiguous)

        guard case .rejected = error else {
            Issue.record("Expected a rejection, got \(error)")
            return
        }
    }

    @Test("An outcome the device never learned is ambiguous, so the order is never offered twice", arguments: [
        PolymarketAPIError.connection(underlying: URLError(.timedOut)),
        PolymarketAPIError.http(statusCode: 502, problemDetail: nil),
    ])
    func unknownOutcomeIsAmbiguous(_ apiError: PolymarketAPIError) {
        #expect(CommonPolymarketCLOBService.placementError(from: apiError).isAmbiguous)
    }

    @Test("A refusal reported inside a success keeps its reason")
    func refusalInsideSuccess() throws {
        let json = #"{"success":false,"errorMsg":"not enough balance / allowance","orderID":null}"#

        let dto = try JSONDecoder().decode(PolymarketDTO.PlaceOrderResponse.self, from: Data(json.utf8))

        #expect(!dto.success)
        #expect(dto.errorMsg == "not enough balance / allowance")
        #expect(dto.orderID == nil)
    }

    @Test("An answer without the optional halves still decodes")
    func sparseResponseIsDecoded() throws {
        let dto = try JSONDecoder().decode(
            PolymarketDTO.PlaceOrderResponse.self,
            from: Data(#"{"success":true}"#.utf8)
        )

        let placement = PolymarketMapper().mapPlaceOrder(dto)

        #expect(placement.orderId == nil)
        #expect(placement.makingAmount == nil)
        #expect(placement.transactionHashes.isEmpty)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderFactoryTests {
    static let depositWallet = "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20"
}

private extension PolymarketPlaceOrderWireFormatTests {
    static let signedOrder = PolymarketSignedOrder(
        order: PolymarketOrder(
            salt: 1_234_567_890,
            maker: "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20",
            signer: "0x4130EFA9E628A991520BE60F2E948A4F9BE52FBC",
            tokenId: "47",
            makerAmount: "72000000",
            takerAmount: "97959180",
            side: .buy,
            timestampMillis: 1_787_300_000_000,
            builder: "0x00000000000000000000000000000000000000000000000000000000000000aa"
        ),
        signature: "0xdeadbeef",
        isNegRisk: false
    )
}

extension PolymarketOrderQuote {
    static let stubBuilderCode = "0x00000000000000000000000000000000000000000000000000000000000000aa"

    static func stub(side: PolymarketOrderSide, notional: Decimal, shares: Decimal) -> PolymarketOrderQuote {
        PolymarketOrderQuote(
            status: .full,
            side: side,
            shares: shares,
            notional: notional,
            expectedExecutionAmount: shares,
            averagePrice: Decimal(string: "0.72")!,
            worstCasePrice: Decimal(string: "0.735")!,
            fees: PolymarketOrderFees(market: 0, builder: 0, total: 0),
            total: notional,
            builderCode: stubBuilderCode,
            minOrderSize: 7,
            minOrderAmount: 1,
            tickSize: Decimal(string: "0.001")!,
            isLive: false
        )
    }
}
