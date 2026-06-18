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
}

public enum TangemPayOfferType: String, Decodable {
    case cardIssueVirtualRain = "CARD_ISSUE_VIRTUAL_RAIN"
    case undefined = "UNDEFINED"

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: raw) ?? .undefined
    }

    public var isAdditionalCardIssue: Bool {
        self == .cardIssueVirtualRain
    }
}

public extension TangemPayCustomerOffer {
    struct Fee: Decodable {
        public let type: String
        public let amount: Decimal
        public let currency: String
        public let description: String?
    }

    struct Data: Decodable {
        public let specificationName: String
        public let orderType: String
    }
}
