//
//  VisaCustomerInfoResponse+CustomerSummary.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]
public extension VisaCustomerInfoResponse.CustomerState {
    init(_ status: TangemPayCustomerSummaryResponse.CustomerStatus) {
        switch status {
        case .new: self = .new
        case .active: self = .active
        case .blocked: self = .blocked
        case .former: self = .former
        case .undefined: self = .undefined
        }
    }
}

// [REDACTED_TODO_COMMENT]
public extension VisaCustomerInfoResponse.KYCStatus {
    init(_ status: TangemPayCustomerSummaryResponse.KYCStatus) {
        switch status {
        case .required: self = .required
        case .inProgress: self = .inProgress
        case .approved: self = .approved
        case .declined: self = .declined
        case .undefined: self = .undefined
        }
    }
}
