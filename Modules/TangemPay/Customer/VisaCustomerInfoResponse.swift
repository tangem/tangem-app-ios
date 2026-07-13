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
    public let customerTariffPlan: CustomerTariffPlan?

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
        depositAddress: String?,
        customerTariffPlan: CustomerTariffPlan? = nil
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
        self.customerTariffPlan = customerTariffPlan
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
        customerTariffPlan = try container.decodeIfPresent(CustomerTariffPlan.self, forKey: .customerTariffPlan)
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
        public let productSpecificationDataType: ProductSpecificationDataType

        enum CodingKeys: String, CodingKey {
            case id
            case cardWalletAddress
            case cardId
            case cid
            case status
            case updatedAt
            case paymentAccountId
            case displayName
            case adminCardLimit
            case actualCardLimit
            case productSpecificationDataType
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            cardWalletAddress = try container.decodeIfPresent(String.self, forKey: .cardWalletAddress)
            cardId = try container.decodeIfPresent(String.self, forKey: .cardId)
            cid = try container.decodeIfPresent(String.self, forKey: .cid)
            status = try container.decodeIfPresent(ProductStatus.self, forKey: .status) ?? .undefined
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .distantPast
            paymentAccountId = try container.decodeIfPresent(String.self, forKey: .paymentAccountId) ?? ""
            displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
            adminCardLimit = try container.decodeIfPresent(CardLimit.self, forKey: .adminCardLimit) ?? CardLimit(amount: 0, periodType: "")
            actualCardLimit = try container.decodeIfPresent(CardLimit.self, forKey: .actualCardLimit)
            productSpecificationDataType = try container.decodeIfPresent(ProductSpecificationDataType.self, forKey: .productSpecificationDataType) ?? .undefined
        }
    }

    enum ProductSpecificationDataType: String, Codable {
        case card = "CARD"
        case account = "ACCOUNT"
        case undefined = "UNDEFINED"

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .undefined
        }
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

    struct CustomerTariffPlan: Codable {
        public let status: Status
        public let source: Source
        public let transitionedAt: Date?
        public let billedAt: Date?
        public let nextBillingAt: Date?
        public let pendingTransitionAt: Date?
        public let tariffPlan: TariffPlan
        public let pendingTariffPlan: TariffPlan?

        public enum Status: String, Codable {
            case active = "ACTIVE"
            case transitioning = "TRANSITIONING"
            case canceled = "CANCELED"
        }

        public enum Source: String, Codable {
            case customer = "CUSTOMER"
            case `default` = "DEFAULT"
        }
    }

    struct TariffPlan: Codable {
        public let id: String
        public let type: String
        public let name: String
        public let descriptionItems: [DescriptionItem]
        public let images: [Image]
        public let fees: [Fee]

        public struct DescriptionItem: Codable {
            public let type: ItemType
            public let order: Int
            public let title: String
            public let body: String

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                type = try container.decode(ItemType.self, forKey: .type)
                order = try container.decode(Int.self, forKey: .order)
                title = try container.decode(String.self, forKey: .title)
                body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
            }

            public enum ItemType: String, Codable {
                case cardRelated = "CARD_RELATED"
                case planRelated = "PLAN_RELATED"

                public init(from decoder: Decoder) throws {
                    let raw = try decoder.singleValueContainer().decode(String.self)
                    self = Self(rawValue: raw) ?? .cardRelated
                }
            }
        }

        public struct Image: Codable {
            public let type: ImageType
            public let url: String

            public enum ImageType: String, Codable {
                case main = "MAIN"
                case thumbnail = "THUMBNAIL"
                case banner = "BANNER"
                case undefined = "UNDEFINED"

                public init(from decoder: Decoder) throws {
                    let raw = try decoder.singleValueContainer().decode(String.self)
                    self = Self(rawValue: raw) ?? .undefined
                }
            }
        }

        public struct Fee: Codable {
            public let type: FeeType
            public let amount: Decimal
            public let currency: String
            public let description: String?
            public let period: Period?

            public enum FeeType: String, Codable {
                case free = "FREE"
                case otc = "OTC"
                case recurring = "RECURRING"
            }

            public enum Period: String, Codable {
                case month = "MONTH"
                case year = "YEAR"
            }
        }
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

    /// First Virtual Account (`ACCOUNT`) product instance, regardless of status.
    var virtualAccountProductInstance: ProductInstance? {
        productInstances.first { $0.productSpecificationDataType == .account }
    }

    /// Card product instances only — excludes Virtual Account (`ACCOUNT`) instances, which share
    /// `cardId == nil` with pending cards and would otherwise be rendered as pending card entries.
    var cardProductInstances: [ProductInstance] {
        productInstances.filter { $0.productSpecificationDataType != .account }
    }
}
