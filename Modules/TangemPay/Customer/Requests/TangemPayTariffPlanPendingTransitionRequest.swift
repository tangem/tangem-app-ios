//
//  TangemPayTariffPlanPendingTransitionRequest.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayTariffPlanPendingTransitionRequest: Encodable {
    let pendingTariffPlanId: String

    enum CodingKeys: String, CodingKey {
        case pendingTariffPlanId = "pending_tariff_plan_id"
    }
}
