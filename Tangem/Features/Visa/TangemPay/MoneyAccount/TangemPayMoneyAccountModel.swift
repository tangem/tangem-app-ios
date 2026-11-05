//
//  TangemPayMoneyAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemPay

protocol TangemPayMoneyAccountModel: AnyObject {
    var customerId: String { get }
    var accountId: String? { get }

    var activation: TangemPayCustomerSummaryResponse.Activation { get }
    var activationPublisher: AnyPublisher<TangemPayCustomerSummaryResponse.Activation, Never> { get }

    var customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan? { get }
    var customerTariffPlanPublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerTariffPlan?, Never> { get }
}
