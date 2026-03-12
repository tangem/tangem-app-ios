//
//  PaymentAccountEnrollmentState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum PaymentAccountEnrollmentState {
    case kycRequired(productInstanceExists: Bool)
    case kycDeclined
    case issuingCard
    case enrolled(customerInfo: VisaCustomerInfoResponse, productInstance: VisaCustomerInfoResponse.ProductInstance)
}
