//
//  TangemPayEnrollmentState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum TangemPayEnrollmentState {
    case notEnrolled
    case kycRequired
    case kycDeclined
    case issuingCard(customerWalletAddress: String)
    case enrolled(customerInfo: VisaCustomerInfoResponse, productInstance: VisaCustomerInfoResponse.ProductInstance)
}
