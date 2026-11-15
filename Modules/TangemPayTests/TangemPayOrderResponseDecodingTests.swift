//
//  TangemPayOrderResponseDecodingTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPay

@Suite("TangemPayOrderResponse decoding")
struct TangemPayOrderResponseDecodingTests {
    @Test("An onboarding order exposes the ids of its child orders once they start")
    func onboardingOrderDecodesChildOrderIds() throws {
        let order = try decode(
            """
            {
              "id": "onb-1",
              "customer_id": "c-1",
              "type": "ONBOARDING_RAIN",
              "status": "PROCESSING",
              "step": "ACCOUNT_ISSUE_BANKING",
              "step_change_code": 0,
              "data": {
                "type": "ONBOARDING_RAIN",
                "customer_wallet_address": "0xwallet",
                "target_tariff_plan_id": "plan-basic",
                "tariff_plan_transition_order_id": "tpt-1",
                "account_issue_banking_order_id": "aib-1"
              }
            }
            """
        )

        #expect(order.type == TangemPayOrderType.onboardingRain.rawValue)
        #expect(order.status == .processing)
        #expect(order.data?.targetTariffPlanId == "plan-basic")
        #expect(order.data?.tariffPlanTransitionOrderId == "tpt-1")
        #expect(order.data?.accountIssueBankingOrderId == "aib-1")
    }

    @Test("An onboarding order before any child started has no child ids")
    func onboardingOrderWithoutChildrenDecodesNilIds() throws {
        let order = try decode(
            """
            {
              "id": "onb-1",
              "customer_id": "c-1",
              "type": "ONBOARDING_RAIN",
              "status": "NEW",
              "step": "INITIALIZATION",
              "data": { "type": "ONBOARDING_RAIN", "customer_wallet_address": "0xwallet" }
            }
            """
        )

        #expect(order.data?.tariffPlanTransitionOrderId == nil)
        #expect(order.data?.accountIssueBankingOrderId == nil)
    }

    // MARK: - Helpers

    private func decode(_ json: String) throws -> TangemPayOrderResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TangemPayOrderResponse.self, from: Data(json.utf8))
    }
}
