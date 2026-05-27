//
//  OnrampApplePayResult.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct OnrampApplePayResult {
    public let paymentToken: String
    public let userData: OnrampNativePaymentRequestItem.UserData

    public init(paymentToken: String, userData: OnrampNativePaymentRequestItem.UserData) {
        self.paymentToken = paymentToken
        self.userData = userData
    }
}
