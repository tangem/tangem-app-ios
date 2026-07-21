//
//  TangemPayTariffPlanSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayTariffPlanSelector {
    func getTariffPlanTransitions() async throws -> TangemPayTariffPlanTransitionsResponse
    func selectTariffPlan(targetTariffPlanId: String, transitionType: TangemPayTariffPlanTransition.TransitionType) async throws
}
