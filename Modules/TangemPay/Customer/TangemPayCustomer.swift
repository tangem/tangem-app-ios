//
//  TangemPayCustomer.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayCustomer: Decodable {
    public let id: String
    public let state: CustomerState
    public let createdAt: Date
    public let productInstance: ProductInstance?
    public let paymentAccount: PaymentAccount?
    public let kyc: KYCInfo?
    public let card: Card?
    public let depositAddress: String?
}

public extension TangemPayCustomer {
    enum CustomerState: String, Decodable {
        case new = "NEW"
        case inProgress = "IN_PROGRESS"
        case active = "ACTIVE"
        case blocked = "BLOCKED"
        case unknown = "UNKNOWN"
    }

    struct ProductInstance: Decodable {
        public let id: String
        public let cardWalletAddress: String?
        public let cardId: String
        public let cid: String?
        public let status: ProductStatus
        public let updatedAt: Date
        public let paymentAccountId: String
    }

    enum ProductStatus: String, Decodable {
        case new = "NEW"
        case readyForManufacturing = "READY_FOR_MANUFACTURING"
        case manufacturing = "MANUFACTURING"
        case sentToDelivery = "SENT_TO_DELIVERY"
        case delivered = "DELIVERED"
        case activating = "ACTIVATING"
        case active = "ACTIVE"
        case blocked = "BLOCKED"
        case deactivating = "DEACTIVATING"
        case deactivated = "DEACTIVATED"
        case canceled = "CANCELED"
        case unknown = "UNKNOWN"
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
        public let expirationMonth: String
        public let expirationYear: String
        public let token: String
        public let embossName: String
        public let cardType: CardType
        public let cardStatus: CardStatus

        @DefaultIfMissing
        public var isPinSet: Bool
    }
}

public extension TangemPayCustomer.Card {
    enum CardType: String, Decodable {
        case virtual = "VIRTUAL"
        case physical = "PHYSICAL"
        case undefined = "UNDEFINED"
    }

    enum CardStatus: String, Decodable {
        case active = "ACTIVE"
        case inactive = "INACTIVE"
        case blocked = "BLOCKED"
        case cancelled = "CANCELLED"
        case undefined = "UNDEFINED"
    }
}
