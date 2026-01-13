//
//  TangemPayAvailabilityService.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol TangemPayAvailabilityService {
    func eligibility() async throws -> TangemPayEligibilityResponse
    func validateDeeplink(deeplinkString: String) async throws -> TangemPayValidateDeeplinkResponse
    func isPaeraCustomer(customerWalletId: String) async throws -> TangemPayIsPaeraCustomerResponse
}
