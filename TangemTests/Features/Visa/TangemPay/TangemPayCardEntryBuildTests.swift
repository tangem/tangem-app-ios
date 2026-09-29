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

@Suite(
    "TangemPayCardEntry.build plastic delivering mapping",
    .enabled(if: FeatureProvider.isAvailable(.tangemPayPlastic))
)
struct TangemPayCardEntryBuildTests {
    @Test("A reissue order with no matching card becomes a delivering plastic entry")
    func reissueOrder_becomesDeliveringPlastic() throws {
        let order = try makeOrder(id: "reissue-1", type: "CARD_REISSUE_PLASTIC_RAIN")

        let entries = TangemPayCardEntry.build(
            cards: [],
            pendingProductInstances: [],
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
            pendingProductInstances: [],
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
            pendingProductInstances: [],
            activeIssueOrders: [order],
            activatingProductInstanceIds: [],
            hiddenSourceProductInstanceIds: []
        )

        #expect(entries.count == 1)
        #expect(entries.first?.order?.id == "virtual-1")
        #expect(entries.first?.plasticCard == nil)
    }

    private func makeOrder(id: String, type: String) throws -> TangemPayOrderResponse {
        let json: [String: Any] = [
            "id": id,
            "customerId": "customer-1",
            "type": type,
            "status": "PROCESSING",
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(TangemPayOrderResponse.self, from: data)
    }
}
