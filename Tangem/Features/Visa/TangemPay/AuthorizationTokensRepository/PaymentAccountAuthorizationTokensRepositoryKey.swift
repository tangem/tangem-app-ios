//
//  PaymentAccountAuthorizationTokensRepositoryKey.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemPay

private struct PaymentAccountAuthorizationTokensRepositoryKey: InjectionKey {
    static var currentValue: PaymentAccountAuthorizationTokensRepository = CommonPaymentAccountAuthorizationTokensRepository()
}

extension InjectedValues {
    var paymentAccountAuthorizationTokensRepository: PaymentAccountAuthorizationTokensRepository {
        get { Self[PaymentAccountAuthorizationTokensRepositoryKey.self] }
        set { Self[PaymentAccountAuthorizationTokensRepositoryKey.self] = newValue }
    }
}
