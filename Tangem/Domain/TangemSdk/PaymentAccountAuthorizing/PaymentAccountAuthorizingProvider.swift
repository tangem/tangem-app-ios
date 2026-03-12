//
//  PaymentAccountAuthorizingProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay

protocol PaymentAccountAuthorizingProvider: AnyObject {
    func makePaymentAccountAuthorizingInteractor(utilities: PaymentAccountUtilities) -> PaymentAccountAuthorizing
}
