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

@Suite("Polymarket redeem call")
struct PolymarketRedeemCallTests {
    private let mapper = PolymarketMapper()

    @Test("A call for the market that was asked about is accepted")
    func acceptsTheCallForTheRequestedMarket() throws {
        let call = try mapper.mapRedeemCall(.stub(), conditionId: Constants.conditionId, isNegRisk: true)

        #expect(call.target == Constants.negRiskAdapter)
        #expect(call.value == "0")
    }

    @Test("A call against any contract but the market's collateral adapter is refused")
    func refusesAnotherContract() {
        let elsewhere = PolymarketDTO.RedeemCallResponse.stub(target: PolymarketApprovalContracts.ctfExchange)

        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCall(elsewhere, conditionId: Constants.conditionId, isNegRisk: true)
        }
    }

    @Test("The adapter follows the market's risk mode")
    func adapterFollowsTheRiskMode() {
        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCall(.stub(), conditionId: Constants.conditionId, isNegRisk: false)
        }

        #expect(throws: Never.self) {
            try mapper.mapRedeemCall(
                .stub(target: PolymarketApprovalContracts.ctfCollateralAdapter),
                conditionId: Constants.conditionId,
                isNegRisk: false
            )
        }
    }

    @Test("An id merely appended to the payload is not an argument")
    func refusesAnAppendedId() {
        let appended = PolymarketDTO.RedeemCallResponse.stub(
            data: "0x01b7037c" + String(repeating: "0", count: 62) + Constants.conditionId.removeHexPrefix()
        )

        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCall(appended, conditionId: Constants.conditionId, isNegRisk: true)
        }
    }

    @Test("A call that names another market is refused before signing")
    func refusesACallForAnotherMarket() {
        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCall(.stub(), conditionId: "0x" + String(repeating: "b", count: 64), isNegRisk: true)
        }
    }

    @Test("A call that moves value is not a redeem")
    func refusesACallThatMovesValue() {
        #expect(throws: PolymarketRedeemError.self) {
            try mapper.mapRedeemCall(.stub(value: "1"), conditionId: Constants.conditionId, isNegRisk: true)
        }
    }

    @Test("The check survives whichever casing the backend answers in")
    func acceptsEitherCasing() {
        let response = PolymarketDTO.RedeemCallResponse.stub(
            data: "0x01b7037c" + String(repeating: "A", count: 64)
        )

        #expect(throws: Never.self) {
            try mapper.mapRedeemCall(response, conditionId: Constants.conditionId, isNegRisk: true)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let negRiskAdapter = PolymarketApprovalContracts.negRiskCtfCollateralAdapter
    static let conditionId = "0x" + String(repeating: "a", count: 64)
}

// MARK: - Fixtures

private extension PolymarketDTO.RedeemCallResponse {
    static func stub(
        target: String = Constants.negRiskAdapter,
        value: String = "0",
        data: String = "0x01b7037c" + String(repeating: "a", count: 64)
    ) -> PolymarketDTO.RedeemCallResponse {
        PolymarketDTO.RedeemCallResponse(target: target, value: value, data: data)
    }
}
