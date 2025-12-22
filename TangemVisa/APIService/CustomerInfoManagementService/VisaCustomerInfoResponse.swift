//
//  VisaCustomerInfoResponse.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaCustomerInfoResponse: Decodable {
    public let id: String
    public let state: CustomerState
    public let createdAt: Date
    public let productInstance: ProductInstance?
    public let paymentAccount: PaymentAccount?
    public let kyc: KYCInfo
    public let card: Card?
    public let depositAddress: String?
}

public extension VisaCustomerInfoResponse {
    enum CustomerState: String, Decodable {
        case new
        case inProgress = "in_progress"
        case active
        case blocked
        case unknown
    }

    struct ProductInstance: Decodable {
        public let id: String
        public let cardWalletAddress: String
        public let cardId: String
        public let cid: String
        public let status: ProductStatus
        public let updatedAt: Date
        public let paymentAccountId: String
    }

    enum ProductStatus: String, Decodable {
        case new
        case readyForManufacturing = "ready_for_manufacturing"
        case manufacturing
        case sentToDelivery = "sent_to_delivery"
        case delivered
        case activating
        case active
        case blocked
        case deactivating
        case deactivated
        case canceled
        case unknown
    }

    struct PaymentAccount: Decodable {
        public let id: String
        public let customerWalletAddress: String
        public let address: String
    }

    struct KYCInfo: Decodable, Identifiable, Equatable {
        public let id: String
        public let provider: String
        public let status: KYCStatus
        public let risk: KYCRisk
        public let reviewAnswer: KYCReviewAnswer
        public let createdAt: Date
    }

    enum KYCStatus: String, Decodable {
        case required = "REQUIRED"
        case approved = "APPROVED"
        case declined = "DECLINED"
        case inProgress = "IN_PROGRESS"
        case expired = "EXPIRED"
        case undefined = "UNDEFINED"
    }

    enum KYCRisk: String, Decodable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        case undefined = "UNDEFINED"
    }

    enum KYCReviewAnswer: String, Decodable {
        case green = "GREEN"
        case red = "RED"
        case undefined = "UNDEFINED"
    }

    struct Card: Decodable {
        public let cardNumberEnd: String
        @DefaultIfMissing
        public var isPINSet: Bool
    }
}
