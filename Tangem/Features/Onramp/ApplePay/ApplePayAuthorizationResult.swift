//
//  ApplePayAuthorizationResult.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import PassKit
import TangemExpress

struct ApplePayAuthorizationResult {
    let provider: OnrampProvider
    let applePayResult: OnrampApplePayResult
    private let resultHandler: (PKPaymentAuthorizationResult) -> Void

    init(
        provider: OnrampProvider,
        applePayResult: OnrampApplePayResult,
        resultHandler: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        self.provider = provider
        self.applePayResult = applePayResult
        self.resultHandler = resultHandler
    }

    func succeed() {
        resultHandler(.init(status: .success, errors: nil))
    }

    func fail(_ error: Error? = nil) {
        resultHandler(.init(status: .failure, errors: error.map { [$0] }))
    }
}
