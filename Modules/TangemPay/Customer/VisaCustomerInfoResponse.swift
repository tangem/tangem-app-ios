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
    /// Legacy single-card field. Restored alongside `productInstances` so the legacy flow can read it directly.
    public let productInstance: ProductInstance?
    public let productInstances: [ProductInstance]
    public let paymentAccount: PaymentAccount?
    public let kyc: KYCInfo?
    /// Legacy single-card field. Restored alongside `cards` so the legacy flow can read it directly.
    public let card: Card?
    public let cards: [Card]
    public let depositAddress: String?

    public init(
        id: String,
        state: CustomerState,
        createdAt: Date,
        productInstance: ProductInstance? = nil,
        productInstances: [ProductInstance],
        paymentAccount: PaymentAccount?,
        kyc: KYCInfo?,
        card: Card? = nil,
        cards: [Card],
        depositAddress: String?
    ) {
        self.id = id
        self.state = state
        self.createdAt = createdAt
        self.productInstance = productInstance
        self.productInstances = productInstances
        self.paymentAccount = paymentAccount
        self.kyc = kyc
        self.card = card
        self.cards = cards
        self.depositAddress = depositAddress
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        state = try container.decode(CustomerState.self, forKey: .state)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        productInstance = try container.decodeIfPresent(ProductInstance.self, forKey: .productInstance)
        // Tolerate legacy-shaped responses that omit the arrays entirely.
        productInstances = try container.decodeIfPresent([ProductInstance].self, forKey: .productInstances) ?? []
        paymentAccount = try container.decodeIfPresent(PaymentAccount.self, forKey: .paymentAccount)
        kyc = try container.decodeIfPresent(KYCInfo.self, forKey: .kyc)
        card = try container.decodeIfPresent(Card.self, forKey: .card)
        cards = try container.decodeIfPresent([Card].self, forKey: .cards) ?? []
        depositAddress = try container.decodeIfPresent(String.self, forKey: .depositAddress)
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
        case undefined = "UNDEFINED"

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .undefined
        }
    }

    struct ProductInstance: Codable {
        public let id: String
        public let cardWalletAddress: String?
        public let cardId: String?
        public let cid: String?
        public let status: ProductStatus
        public let updatedAt: Date
        public let paymentAccountId: String
        public let displayName: String?
        public let adminCardLimit: CardLimit
        public let actualCardLimit: CardLimit?
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
        case undefined = "UNDEFINED"

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .undefined
        }
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

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .undefined
        }
    }

    enum KYCRisk: String, Codable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        case undefined = "UNDEFINED"

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .undefined
        }
    }

    enum KYCReviewAnswer: String, Codable {
        case green = "GREEN"
        case red = "RED"
        case undefined = "UNDEFINED"

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .undefined
        }
    }

    struct Card: Codable {
        public let id: String
        public let cardNumberEnd: String
        public let expirationMonth: String
        public let expirationYear: String
        public let token: String
        public let embossName: String
        public let cardType: CardType
        public let cardStatus: CardStatus
        public let isPinSet: Bool

        public init(
            id: String,
            cardNumberEnd: String,
            expirationMonth: String,
            expirationYear: String,
            token: String,
            embossName: String,
            cardType: CardType,
            cardStatus: CardStatus,
            isPinSet: Bool
        ) {
            self.id = id
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

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .undefined
        }
    }

    enum CardStatus: String, Codable {
        case active = "ACTIVE"
        case inactive = "INACTIVE"
        case blocked = "BLOCKED"
        case canceled = "CANCELED"
        case undefined = "UNDEFINED"

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .undefined
        }
    }
}

public extension VisaCustomerInfoResponse {
    func productInstance(forCardId cardId: String) -> ProductInstance? {
        productInstances.first { $0.cardId == cardId }
    }

    func card(forCardId cardId: String) -> Card? {
        cards.first { $0.id == cardId }
    }
}
