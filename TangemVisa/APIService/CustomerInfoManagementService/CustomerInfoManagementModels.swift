//
//  VisaCustomerInfoResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaCustomerInfoResponse: Decodable {
    public let customerId: String
    public let customerNumber: String?
    public let customerStatus: String
    public let createdAt: Date
    public let paymentAccounts: [PaymentAccount]?
    public let productInstances: [ProductInstance]?
    public let kyc: KYC?
    public let kyt: KYT?
    public let profile: Profile?
}

public extension VisaCustomerInfoResponse {
    struct PaymentAccount: Decodable {
        public let id: String
        public let customerWalletAddress: String
        public let paymentAccountAddress: String
    }

    struct ProductInstance: Decodable {
        public let id: String
        public let paymentAccountId: String
        public let cid: String?
        public let status: String
        public let issuer: String
    }

    struct KYC: Decodable {
        public let status: String
        public let risk: String
        public let updatedAt: String
    }

    struct KYT: Decodable {
        public let risk: String
        public let updatedAt: String
    }

    struct Profile: Decodable {
        public let firstName: String
        public let lastName: String
    }
}

public enum KYCStatus: String {
    case required = "REQUIRED"
    case inProgress = "IN_PROGRESS"
    case passed = "PASSED"
    case failed = "FAILED"
    case blocked = "BLOCKED"
}

public enum KYCRisk: String {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case veryHigh = "VERY_HIGH"
    case unknown = "UNKNOWN"
}

public enum KYTRisk: String {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case veryHigh = "VERY_HIGH"
    case unknown = "UNKNOWN"
}
