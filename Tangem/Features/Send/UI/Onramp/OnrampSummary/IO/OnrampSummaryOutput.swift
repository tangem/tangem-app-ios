//
//  OnrampSummaryOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import PassKit
import TangemExpress

protocol OnrampSummaryOutput: AnyObject {
    func userDidRequestOnramp(provider: OnrampProvider)
    func userDidAuthorizeNativePayment(
        provider: OnrampProvider,
        applePayResult: OnrampApplePayResult,
        resultHandler: @escaping (PKPaymentAuthorizationResult) -> Void
    )
}
