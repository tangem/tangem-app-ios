//
//  TangemPayCustomerOffersResponse.swift
//  TangemPay
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public typealias TangemPayCustomerOffersResponse = [TangemPayCustomerOffer]

public struct TangemPayCustomerOffer: Decodable {
    public let type: TangemPayOfferType
    public let fee: Fee?
    public let data: Data?
    public let images: [VisaCustomerInfoResponse.TariffPlan.Image]?

    public var mainImageURL: URL? {
        images?.first { $0.type == .main }.flatMap { URL(string: $0.url) }
    }
}

public enum TangemPayOfferType: String, Decodable {
    case cardIssueVirtualRain = "CARD_ISSUE_VIRTUAL_RAIN"
    case cardIssuePlasticRain = "CARD_ISSUE_PLASTIC_RAIN"
    case cardReissuePlasticRain = "CARD_REISSUE_PLASTIC_RAIN"
    case undefined = "UNDEFINED"

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: raw) ?? .undefined
    }

    public var isAdditionalCardIssue: Bool {
        self == .cardIssueVirtualRain
    }

    public var isPlastic: Bool {
        self == .cardIssuePlasticRain
    }

    public var isPlasticReissue: Bool {
        self == .cardReissuePlasticRain
    }
}

public extension TangemPayCustomerOffer {
    struct Fee: Decodable {
        public let type: String?
        public let amount: Decimal
        public let currency: String
        public let description: String?
    }

    struct Data: Decodable {
        public let specificationName: String?
        public let orderType: String
        public let deliveryEtaMinDays: Int?
        public let deliveryEtaMaxDays: Int?
    }
}
