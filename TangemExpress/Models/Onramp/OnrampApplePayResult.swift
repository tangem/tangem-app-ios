//
//  OnrampApplePayResult.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// PassKit-free model that carries the Apple Pay authorization result.
/// Lives in TangemExpress so the interactor layer can reference it without importing PassKit.
public struct OnrampApplePayResult {
    public let paymentToken: String
    public let userData: OnrampNativePaymentRequestItem.UserData

    public init(paymentToken: String, userData: OnrampNativePaymentRequestItem.UserData) {
        self.paymentToken = paymentToken
        self.userData = userData
    }
}
