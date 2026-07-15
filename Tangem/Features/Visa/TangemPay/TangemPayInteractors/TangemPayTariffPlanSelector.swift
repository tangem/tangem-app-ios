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

    /// Places a `TARIFF_PLAN_TRANSITION` order for the plan chosen on the Select plan screen and
    /// starts issuing polling. `transitionType` distinguishes onboarding Basic (`ACTIVATION`) from
    /// Plus/upgrade (`UPGRADE`).
    func selectTariffPlan(
        targetTariffPlanId: String,
        transitionType: TangemPayTariffPlanTransition.TransitionType
    ) async throws
}
