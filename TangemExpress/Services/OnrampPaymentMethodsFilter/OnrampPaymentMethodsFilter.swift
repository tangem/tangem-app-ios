//
//  OnrampPaymentMethodsFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import PassKit

struct OnrampPaymentMethodsFilter {
    func isSupported(paymentMethod: OnrampPaymentMethod) -> Bool {
        if paymentMethod.type == .googlePay {
            return false
        }

        if paymentMethod.type == .applePay {
            // We cannot check if the user has an setup card
            // because this requires the turning on of the "ApplePay" function
            // In capabilities which gives us additional trouble
            // Then we are using the `canMakePayments()` method which return flag about
            // the hardware and parental controls allow making payments
            return PKPaymentAuthorizationViewController.canMakePayments()
        }

        return true
    }
}
