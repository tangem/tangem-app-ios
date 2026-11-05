//
//  TangemPayMoneyAccount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemPay

final class TangemPayMoneyAccount: TangemPayMoneyAccountModel {
    let customerId: String

    private let bankingAccountSubject: CurrentValueSubject<TangemPayCustomerSummaryResponse.BankingAccount, Never>
    private let customerTariffPlanSubject: CurrentValueSubject<VisaCustomerInfoResponse.CustomerTariffPlan?, Never>

    init(
        customerId: String,
        bankingAccount: TangemPayCustomerSummaryResponse.BankingAccount
    ) {
        self.customerId = customerId
        bankingAccountSubject = CurrentValueSubject(bankingAccount)
        customerTariffPlanSubject = CurrentValueSubject(nil)
    }

    // MARK: Public Interface

    var accountId: String? {
        bankingAccountSubject.value.id
    }

    var activation: TangemPayCustomerSummaryResponse.Activation {
        bankingAccountSubject.value.activation
    }

    var activationPublisher: AnyPublisher<TangemPayCustomerSummaryResponse.Activation, Never> {
        bankingAccountSubject
            .map(\.activation)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan? {
        customerTariffPlanSubject.value
    }

    var customerTariffPlanPublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerTariffPlan?, Never> {
        customerTariffPlanSubject.eraseToAnyPublisher()
    }

    // MARK: Internal Interface

    func update(bankingAccount: TangemPayCustomerSummaryResponse.BankingAccount) {
        bankingAccountSubject.send(bankingAccount)
    }

    func update(customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan?) {
        customerTariffPlanSubject.send(customerTariffPlan)
    }
}
