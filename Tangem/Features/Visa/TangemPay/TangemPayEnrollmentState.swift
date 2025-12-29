//
//  TangemPayEnrollmentState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa

enum TangemPayEnrollmentState {
    case notEnrolled
    case kyc
    case issuingCard(customerWalletAddress: String)
    case enrolled(customerInfo: VisaCustomerInfoResponse, productInstance: VisaCustomerInfoResponse.ProductInstance)
}
