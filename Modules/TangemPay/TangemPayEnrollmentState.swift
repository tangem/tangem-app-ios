//
//  TangemPayEnrollmentState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum TangemPayEnrollmentState {
    case kycRequired
    case kycDeclined
    case issuingCard
    case enrolled(customerInfo: VisaCustomerInfoResponse, productInstance: VisaCustomerInfoResponse.ProductInstance)
}
