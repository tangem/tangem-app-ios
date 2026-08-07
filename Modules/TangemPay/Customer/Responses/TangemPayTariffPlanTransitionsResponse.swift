//
//  TangemPayTariffPlanTransitionsResponse.swift
//  TangemPay
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public typealias TangemPayTariffPlanTransitionsResponse = [TangemPayTariffPlanTransition]

public struct TangemPayTariffPlanTransition: Decodable {
    public let type: TransitionType
    public let tariffPlan: VisaCustomerInfoResponse.TariffPlan

    public enum TransitionType: String, Decodable {
        case activation = "ACTIVATION"
        case upgrade = "UPGRADE"
        case downgrade = "DOWNGRADE"
    }
}
