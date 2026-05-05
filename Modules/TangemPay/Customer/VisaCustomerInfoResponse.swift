//
//  VisaCustomerInfoResponse.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaCustomerInfoResponse: Codable {
    public let id: String
    public let state: CustomerState
    public let createdAt: Date
    public let productInstance: ProductInstance?
    public let paymentAccount: PaymentAccount?
    public let kyc: KYCInfo?
    public let card: Card?
    public let depositAddress: String?

    public init(
        id: String,
        state: CustomerState,
        createdAt: Date,
        productInstance: ProductInstance?,
        paymentAccount: PaymentAccount?,
        kyc: KYCInfo?,
        card: Card?,
        depositAddress: String?
    ) {
        self.id = id
        self.state = state
        self.createdAt = createdAt
        self.productInstance = productInstance
        self.paymentAccount = paymentAccount
        self.kyc = kyc
        self.card = card
        self.depositAddress = depositAddress
    }
}

public extension VisaCustomerInfoResponse {
    enum CustomerState: String, Codable {
        case new = "NEW"
        case inProgress = "IN_PROGRESS"
        case active = "ACTIVE"
        case blocked = "BLOCKED"
        case former = "FORMER"
        case unknown = "UNKNOWN"
    }

    struct ProductInstance: Codable {
        public let id: String
        public let cardWalletAddress: String?
        public let cardId: String
        public let cid: String?
        public let status: ProductStatus
        public let updatedAt: Date
        public let paymentAccountId: String
        public let displayName: String
        public let adminCardLimit: CardLimit
        public let actualCardLimit: CardLimit
    }

    enum ProductStatus: String, Codable {
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

    struct PaymentAccount: Codable {
        public let id: String
        public let customerWalletAddress: String
        public let address: String?
    }

    struct KYCInfo: Codable, Identifiable, Equatable {
        public let id: String
        public let provider: String
        public let status: KYCStatus
        public let risk: KYCRisk
        public let reviewAnswer: KYCReviewAnswer
        public let createdAt: Date
    }

    enum KYCStatus: String, Codable {
        case required = "REQUIRED"
        case approved = "APPROVED"
        case declined = "DECLINED"
        case inProgress = "IN_PROGRESS"
        case expired = "EXPIRED"
        case undefined = "UNDEFINED"
    }

    enum KYCRisk: String, Codable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        case undefined = "UNDEFINED"
    }

    enum KYCReviewAnswer: String, Codable {
        case green = "GREEN"
        case red = "RED"
        case undefined = "UNDEFINED"
    }

    struct Card: Codable {
        public let cardNumberEnd: String
        public let expirationMonth: String
        public let expirationYear: String
        public let token: String
        public let embossName: String
        public let cardType: CardType
        public let cardStatus: CardStatus
        public let isPinSet: Bool

        public init(
            cardNumberEnd: String,
            expirationMonth: String,
            expirationYear: String,
            token: String,
            embossName: String,
            cardType: CardType,
            cardStatus: CardStatus,
            isPinSet: Bool
        ) {
            self.cardNumberEnd = cardNumberEnd
            self.expirationMonth = expirationMonth
            self.expirationYear = expirationYear
            self.token = token
            self.embossName = embossName
            self.cardType = cardType
            self.cardStatus = cardStatus
            self.isPinSet = isPinSet
        }
    }

    struct CardLimit: Codable {
        public let amount: Int
        public let periodType: String
    }
}

public extension VisaCustomerInfoResponse.Card {
    enum CardType: String, Codable {
        case virtual = "VIRTUAL"
        case physical = "PHYSICAL"
        case undefined = "UNDEFINED"
    }

    enum CardStatus: String, Codable {
        case active = "ACTIVE"
        case inactive = "INACTIVE"
        case blocked = "BLOCKED"
        case cancelled = "CANCELLED"
        case undefined = "UNDEFINED"
    }
}
