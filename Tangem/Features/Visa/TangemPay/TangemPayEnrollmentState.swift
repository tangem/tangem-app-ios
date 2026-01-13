//
//  TangemPayEnrollmentState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemPay

enum TangemPayEnrollmentState {
    case notEnrolled
    case kyc
    case issuingCard(customerWalletAddress: String)
    case enrolled(customerInfo: TangemPayCustomer, productInstance: TangemPayCustomer.ProductInstance)
}
