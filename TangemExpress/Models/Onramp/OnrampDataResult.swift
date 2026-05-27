//
//  OnrampDataResult.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum OnrampDataResult {
    /// Native payment succeeded — no widget redirect needed
    case nativePayment(OnrampNativePaymentData)
    /// Native payment failed on backend — fallback to provider widget
    case widget(OnrampRedirectData)
}
