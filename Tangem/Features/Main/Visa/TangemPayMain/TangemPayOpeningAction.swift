//
//  TangemPayOpeningAction.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// What the screen does once something from outside has opened it — the `screen` parameter of a
/// `tangem://pay-account` link or the kind of a payment push.
enum TangemPayOpeningAction: String {
    case addFunds = "add_funds"
    case currentPlan = "current_plan"
    case changePlan = "change_plan"
    case orderCard = "order_card"
    case cashback
    case vaOnramp = "va_onramp"
    case vaOnrampDetails = "va_onramp_details"
    case selectPlan = "select_plan"
}
