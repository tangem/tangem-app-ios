//
//  TangemPayCardEntryBuildTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPay
@testable import Tangem

@Suite("TangemPayCardEntry.build mapping")
struct TangemPayCardEntryBuildTests {
    @Test("A reissue order with no matching card becomes a delivering plastic entry")
    func reissueOrder_becomesDeliveringPlastic() throws {
        let order = try makeOrder(id: "reissue-1", type: "CARD_REISSUE_PLASTIC_RAIN")

        let entries = TangemPayCardEntry.build(
            cards: [],
            activeIssueOrders: [order],
            activatingProductInstanceIds: [],
            hiddenSourceProductInstanceIds: []
        )

        #expect(entries.count == 1)
        #expect(entries.first?.plasticCard?.isDelivering == true)
    }

    @Test("An issue order still becomes a delivering plastic entry")
    func issueOrder_becomesDeliveringPlastic() throws {
        let order = try makeOrder(id: "issue-1", type: "CARD_ISSUE_PLASTIC_RAIN")

        let entries = TangemPayCardEntry.build(
            cards: [],
            activeIssueOrders: [order],
            activatingProductInstanceIds: [],
            hiddenSourceProductInstanceIds: []
        )

        #expect(entries.count == 1)
        #expect(entries.first?.plasticCard?.isDelivering == true)
    }

    @Test("A non-plastic order stays a generic issuing entry")
    func nonPlasticOrder_staysIssuing() throws {
        let order = try makeOrder(id: "virtual-1", type: "CARD_ISSUE_VIRTUAL_RAIN")

        let entries = TangemPayCardEntry.build(
            cards: [],
            activeIssueOrders: [order],
            activatingProductInstanceIds: [],
            hiddenSourceProductInstanceIds: []
        )

        #expect(entries.count == 1)
        #expect(entries.first?.order?.id == "virtual-1")
        #expect(entries.first?.plasticCard == nil)
    }

    @Test("Without cards or active orders, no entries are produced")
    func noCardsNoOrders_yieldsNoEntries() {
        let entries = TangemPayCardEntry.build(
            cards: [],
            activeIssueOrders: [],
            activatingProductInstanceIds: [],
            hiddenSourceProductInstanceIds: []
        )

        #expect(entries.isEmpty)
    }

    @Test("A virtual issue order exposes its product instance id")
    func virtualOrder_exposesProductInstanceId() throws {
        let order = try makeOrder(id: "virtual-1", type: "CARD_ISSUE_VIRTUAL_RAIN", productInstanceId: "pi-1")

        let entries = TangemPayCardEntry.build(
            cards: [],
            activeIssueOrders: [order],
            activatingProductInstanceIds: [],
            hiddenSourceProductInstanceIds: []
        )

        #expect(entries.count == 1)
        #expect(entries.first?.isIssuing == true)
        #expect(entries.first?.productInstanceId == "pi-1")
    }

    @Test("An awaiting-deposit order becomes a ghost issuing entry")
    func awaitingDepositOrder_isGhostIssuing() throws {
        let order = try makeOrder(id: "tariff-1", type: "TARIFF_PLAN_TRANSITION", step: "AWAITING_DEPOSIT")

        let entries = TangemPayCardEntry.build(
            cards: [],
            activeIssueOrders: [order],
            activatingProductInstanceIds: [],
            hiddenSourceProductInstanceIds: []
        )

        #expect(entries.count == 1)
        #expect(entries.first?.isIssuing == true)
        #expect(entries.first?.isGhost == true)
    }

    private func makeOrder(
        id: String,
        type: String,
        productInstanceId: String? = nil,
        step: String? = nil
    ) throws -> TangemPayOrderResponse {
        var json: [String: Any] = [
            "id": id,
            "customerId": "customer-1",
            "type": type,
            "status": "PROCESSING",
        ]
        if let productInstanceId {
            json["data"] = ["productInstanceId": productInstanceId]
        }
        if let step {
            json["step"] = step
        }
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(TangemPayOrderResponse.self, from: data)
    }
}
