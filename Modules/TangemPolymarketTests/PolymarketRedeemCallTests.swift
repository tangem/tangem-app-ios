//
//  PolymarketRedeemCallTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemPolymarket

@Suite("Polymarket redeem call V1")
struct PolymarketRedeemCallTests {
    private let mapper = PolymarketMapper()

    @Test("A call for the market that was asked about is accepted")
    func acceptsTheCallForTheRequestedMarket() throws {
        let calls = try mapper.mapRedeemCalls(.v1(), request: .v1(isNegRisk: true))

        #expect(calls.count == 1)
        #expect(calls.first?.target == Constants.negRiskAdapter)
        #expect(calls.first?.value == "0")
    }

    @Test("A call against any contract but the market's collateral adapter is refused")
    func refusesAnotherContract() {
        let elsewhere = PolymarketDTO.RedeemCallResponse.v1(target: PolymarketApprovalContracts.ctfExchange)

        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCalls(elsewhere, request: .v1(isNegRisk: true))
        }
    }

    @Test("The adapter follows the market's risk mode")
    func adapterFollowsTheRiskMode() {
        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCalls(.v1(), request: .v1(isNegRisk: false))
        }

        #expect(throws: Never.self) {
            try mapper.mapRedeemCalls(
                .v1(target: PolymarketApprovalContracts.ctfCollateralAdapter),
                request: .v1(isNegRisk: false)
            )
        }
    }

    @Test("An id merely appended to the payload is not an argument")
    func refusesAnAppendedId() {
        let appended = PolymarketDTO.RedeemCallResponse.v1(
            data: "0x01b7037c" + String(repeating: "0", count: 62) + Constants.conditionId.removeHexPrefix()
        )

        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCalls(appended, request: .v1(isNegRisk: true))
        }
    }

    @Test("A call that names another market is refused before signing")
    func refusesACallForAnotherMarket() {
        let request = PolymarketRedeemCallRequest(
            conditionId: "0x" + String(repeating: "b", count: 64),
            assetId: "1",
            isNegRisk: true,
            version: .v1
        )

        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCalls(.v1(), request: request)
        }
    }

    @Test("A call that moves value is not a redeem")
    func refusesACallThatMovesValue() {
        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCalls(.v1(value: "1"), request: .v1(isNegRisk: true))
        }
    }

    @Test("The check survives whichever casing the backend answers in")
    func acceptsEitherCasing() {
        let response = PolymarketDTO.RedeemCallResponse.v1(data: "0x01b7037c" + String(repeating: "A", count: 64))

        #expect(throws: Never.self) {
            try mapper.mapRedeemCalls(response, request: .v1(isNegRisk: true))
        }
    }

    @Test("A V1 market redeems in exactly one call")
    func refusesASecondV1Call() {
        let call = PolymarketDTO.RedeemCall(
            target: Constants.negRiskAdapter,
            value: "0",
            data: "0x01b7037c" + String(repeating: "a", count: 64)
        )
        let response = PolymarketDTO.RedeemCallResponse(version: "v1", calls: [call, call])

        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCalls(response, request: .v1(isNegRisk: true))
        }
    }
}

// MARK: - V2

@Suite("Polymarket redeem call V2")
struct PolymarketRedeemCallV2Tests {
    private let mapper = PolymarketMapper()

    @Test("A single Router call for the held outcome is accepted")
    func acceptsOneCall() throws {
        let calls = try mapper.mapRedeemCalls(.v2([.redeem(outcome: 1)]), request: .v2())

        #expect(calls == [PolymarketRelayedBatch.Call(target: PolymarketApprovalContracts.routerV3, data: Calldata.redeem(outcome: 1))])
    }

    @Test("Both outcomes are redeemed in the order the backend sent them, untouched")
    func acceptsTwoCallsInOrder() throws {
        let calls = try mapper.mapRedeemCalls(.v2([.redeem(outcome: 1), .redeem(outcome: 0)]), request: .v2())

        #expect(calls.map(\.data) == [Calldata.redeem(outcome: 1), Calldata.redeem(outcome: 0)])
        #expect(calls.allSatisfy { $0.target == PolymarketApprovalContracts.routerV3 })
    }

    @Test("A position of either outcome names the same condition")
    func eitherOutcomeIdentifiesTheCondition() throws {
        let request = PolymarketRedeemCallRequest(
            conditionId: Constants.conditionId,
            assetId: Constants.v2AssetIdOutcome0,
            isNegRisk: false,
            version: .v2
        )

        #expect(throws: Never.self) {
            try mapper.mapRedeemCalls(.v2([.redeem(outcome: 1)]), request: request)
        }
    }

    @Test("The Router address passes in any casing")
    func routerCasing() {
        let call = PolymarketDTO.RedeemCall(target: PolymarketApprovalContracts.routerV3.lowercased(), value: "0", data: Calldata.redeem(outcome: 0))

        #expect(throws: Never.self) {
            try mapper.mapRedeemCalls(.v2([call]), request: .v2())
        }
    }

    @Test("A V2 call is refused", arguments: RejectedV2Call.allCases)
    func refusesABrokenCall(_ rejected: RejectedV2Call) {
        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCalls(rejected.response, request: .v2())
        }
    }

    @Test("A response for another version than the position's is refused", arguments: [
        ("v1", Optional(PolymarketMarketVersion.v2)),
        ("v2", Optional(PolymarketMarketVersion.v1)),
        ("v3", Optional(PolymarketMarketVersion.unknown("v3"))),
        ("v2", PolymarketMarketVersion?.none),
    ])
    func refusesAVersionMismatch(_ responseVersion: String, _ positionVersion: PolymarketMarketVersion?) {
        let response = PolymarketDTO.RedeemCallResponse(version: responseVersion, calls: [.redeem(outcome: 1)])
        let request = PolymarketRedeemCallRequest(
            conditionId: Constants.conditionId,
            assetId: Constants.v2AssetIdOutcome1,
            isNegRisk: false,
            version: positionVersion
        )

        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCalls(response, request: request)
        }
    }

    @Test("The V2 market's own condition id is not what the Router call has to carry")
    func conditionIdOfTheMarketIsNotChecked() {
        let request = PolymarketRedeemCallRequest(
            conditionId: "0x" + String(repeating: "b", count: 64),
            assetId: Constants.v2AssetIdOutcome1,
            isNegRisk: true,
            version: .v2
        )

        #expect(throws: Never.self) {
            try mapper.mapRedeemCalls(.v2([.redeem(outcome: 1)]), request: request)
        }
    }
}

enum RejectedV2Call: CaseIterable {
    case noCalls
    case threeCalls
    case adapterTarget
    case foreignTarget
    case foreignSelector
    case anotherCondition
    case outcomeTwo
    case sameOutcomeTwice
    case zeroAmount
    case extraWord
    case missingWord
    case movesValue
    case notHex

    var response: PolymarketDTO.RedeemCallResponse {
        switch self {
        case .noCalls:
            .v2([])
        case .threeCalls:
            .v2([.redeem(outcome: 0), .redeem(outcome: 1), .redeem(outcome: 0)])
        case .adapterTarget:
            .v2([PolymarketDTO.RedeemCall(target: PolymarketApprovalContracts.ctfCollateralAdapter, value: "0", data: Calldata.redeem(outcome: 1))])
        case .foreignTarget:
            .v2([PolymarketDTO.RedeemCall(target: "0x4130efa9e628a991520be60f2e948a4f9be52fbc", value: "0", data: Calldata.redeem(outcome: 1))])
        case .foreignSelector:
            .v2([.raw("0x01b7037c" + Calldata.conditionWord + Calldata.word(1) + Calldata.word(5))])
        case .anotherCondition:
            .v2([.raw("0xd217a3cc" + String(repeating: "b", count: 62) + "00" + Calldata.word(1) + Calldata.word(5))])
        case .outcomeTwo:
            .v2([.raw("0xd217a3cc" + Calldata.conditionWord + Calldata.word(2) + Calldata.word(5))])
        case .sameOutcomeTwice:
            .v2([.redeem(outcome: 1), .redeem(outcome: 1)])
        case .zeroAmount:
            .v2([.raw("0xd217a3cc" + Calldata.conditionWord + Calldata.word(1) + Calldata.word(0))])
        case .extraWord:
            .v2([.raw(Calldata.redeem(outcome: 1) + Calldata.word(0))])
        case .missingWord:
            .v2([.raw("0xd217a3cc" + Calldata.conditionWord + Calldata.word(1))])
        case .movesValue:
            .v2([PolymarketDTO.RedeemCall(target: PolymarketApprovalContracts.routerV3, value: "1", data: Calldata.redeem(outcome: 1))])
        case .notHex:
            .v2([.raw("0xd217a3cc" + Calldata.conditionWord + Calldata.word(1) + String(repeating: "z", count: 64))])
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let negRiskAdapter = PolymarketApprovalContracts.negRiskCtfCollateralAdapter
    static let conditionId = "0x" + String(repeating: "a", count: 64)

    static let v2AssetIdOutcome0 = "42936607822772754351500781183730325726151312114983019402690548478040523031040"
    static let v2AssetIdOutcome1 = "42936607822772754351500781183730325726151312114983019402690548478040523031041"
}

private enum Calldata {
    static let conditionWord = "5eed" + String(repeating: "42", count: 29) + "00"

    static func word(_ value: Int) -> String {
        let hex = String(value, radix: 16)
        return String(repeating: "0", count: 64 - hex.count) + hex
    }

    static func redeem(outcome: Int) -> String {
        "0xd217a3cc" + conditionWord + word(outcome) + word(1_500_000)
    }
}

// MARK: - Fixtures

private extension PolymarketDTO.RedeemCallResponse {
    static func v1(
        target: String = Constants.negRiskAdapter,
        value: String = "0",
        data: String = "0x01b7037c" + String(repeating: "a", count: 64)
    ) -> PolymarketDTO.RedeemCallResponse {
        PolymarketDTO.RedeemCallResponse(
            version: "v1",
            calls: [PolymarketDTO.RedeemCall(target: target, value: value, data: data)]
        )
    }

    static func v2(_ calls: [PolymarketDTO.RedeemCall]) -> PolymarketDTO.RedeemCallResponse {
        PolymarketDTO.RedeemCallResponse(version: "v2", calls: calls)
    }
}

private extension PolymarketDTO.RedeemCall {
    static func redeem(outcome: Int) -> PolymarketDTO.RedeemCall {
        raw(Calldata.redeem(outcome: outcome))
    }

    static func raw(_ data: String) -> PolymarketDTO.RedeemCall {
        PolymarketDTO.RedeemCall(target: PolymarketApprovalContracts.routerV3, value: "0", data: data)
    }
}

private extension PolymarketRedeemCallRequest {
    static func v1(isNegRisk: Bool) -> PolymarketRedeemCallRequest {
        PolymarketRedeemCallRequest(conditionId: Constants.conditionId, assetId: "1", isNegRisk: isNegRisk, version: .v1)
    }

    static func v2() -> PolymarketRedeemCallRequest {
        PolymarketRedeemCallRequest(
            conditionId: Constants.conditionId,
            assetId: Constants.v2AssetIdOutcome1,
            isNegRisk: false,
            version: .v2
        )
    }
}

// MARK: - Decoding and errors

@Suite("Polymarket redeem call response")
struct PolymarketRedeemCallResponseTests {
    @Test("The calls array is what is read, the deprecated single call is ignored")
    func readsCalls() throws {
        let json = """
        {
          "version": "v2",
          "calls": [
            { "target": "0x12121212006e4cd160d18e3f00711da5c3372600", "value": "0", "data": "0x01" },
            { "target": "0x12121212006e4cd160d18e3f00711da5c3372600", "value": "0", "data": "0x02" }
          ],
          "target": "0x12121212006e4cd160d18e3f00711da5c3372600",
          "value": "0",
          "data": "0x01"
        }
        """

        let response = try JSONDecoder().decode(PolymarketDTO.RedeemCallResponse.self, from: Data(json.utf8))

        #expect(response.version == "v2")
        #expect(response.calls.map(\.data) == ["0x01", "0x02"])
    }

    @Test("409 on asking for the redeem calls means there is nothing left to redeem")
    func conflictOnTheCallIsNothingToRedeem() {
        let error = PolymarketRedeemError.forRedeemCall(PolymarketRedeemError(apiError: .http(statusCode: 409, problemDetail: nil)))

        #expect(error.isNothingToRedeem)
    }

    @Test("409 on submitting or reading a claim stays a conflict and is never taken for done")
    func conflictElsewhereIsNotNothingToRedeem() {
        let error = PolymarketRedeemError(apiError: .http(statusCode: 409, problemDetail: nil))

        #expect(!error.isNothingToRedeem)
        #expect(error.isOther)
    }

    @Test("Other refusals of the redeem call keep their meaning", arguments: [400, 404, 422, 502])
    func otherCallRefusalsAreKept(_ statusCode: Int) {
        let error = PolymarketRedeemError.forRedeemCall(PolymarketRedeemError(apiError: .http(statusCode: statusCode, problemDetail: nil)))

        #expect(!error.isNothingToRedeem)
    }
}
