//
//  ApplePayButtonPaymentAuthorizationHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol ApplePayButtonPaymentAuthorizationHandler: AnyObject {
    func handleApplePayAuthorization(_ result: ApplePayAuthorizationResult)
}
