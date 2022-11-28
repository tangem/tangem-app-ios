//
//  LimitOrderParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum ExchangeOrderStatus: Int {
    case valid = 1
    case temporaryInvalid = 2
    case invalid = 3
}

public struct OrdersForAddressParameters: Encodable {
    public var address: String
    public var page: Int
    public var limit: Int
    public var statuses: [ExchangeOrderStatus]
    public var makerAsset: String?
    public var takerAsset: String?

    public init(
        address: String,
        page: Int = 1,
        limit: Int = 100,
        statuses: [ExchangeOrderStatus] = [],
        makerAsset: String? = nil,
        takerAsset: String? = nil
    ) {
        self.address = address
        self.page = page
        self.limit = limit
        self.statuses = statuses
        self.takerAsset = takerAsset
        self.makerAsset = makerAsset
    }

    enum CodingKeys: CodingKey {
        case address
        case page
        case limit
        case statuses
        case makerAsset
        case takerAsset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encode(page, forKey: .page)
        try container.encode(limit, forKey: .limit)

        let statuses = "\(statuses.map({ $0.rawValue }).sorted())"
        try container.encode(statuses, forKey: .statuses)

        try container.encodeIfPresent(makerAsset, forKey: .makerAsset)
        try container.encodeIfPresent(takerAsset, forKey: .takerAsset)
    }
}

public struct AllOrdersParameters: Encodable {
    public var page: Int
    public var limit: Int
    public var statuses: [ExchangeOrderStatus]
    public var makerAsset: String?
    public var takerAsset: String?

    public init(
        page: Int = 1,
        limit: Int = 100,
        statuses: [ExchangeOrderStatus] = [],
        makerAsset: String? = nil,
        takerAsset: String? = nil
    ) {
        self.page = page
        self.limit = limit
        self.statuses = statuses
        self.takerAsset = takerAsset
        self.makerAsset = makerAsset
    }

    enum CodingKeys: CodingKey {
        case page
        case limit
        case statuses
        case makerAsset
        case takerAsset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(page, forKey: .page)
        try container.encode(limit, forKey: .limit)

        if !statuses.isEmpty {
            let statuses = "\(statuses.map({ $0.rawValue }).sorted())"
            try container.encode(statuses, forKey: .statuses)
        }

        try container.encodeIfPresent(makerAsset, forKey: .makerAsset)
        try container.encodeIfPresent(takerAsset, forKey: .takerAsset)
    }
}

