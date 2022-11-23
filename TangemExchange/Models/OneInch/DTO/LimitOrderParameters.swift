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

public struct OrdersForAddressParameters {
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

    func parameters() -> [String: Any] {
        var params: [String: Any] = [:]
        params["page"] = page
        params["limit"] = limit
        params["statuses"] = "\(statuses.map({ $0.rawValue }).sorted())"
        if let takerAsset = takerAsset {
            params["takerAsset"] = takerAsset
        }
        if let makerAsset = makerAsset {
            params["makerAsset"] = makerAsset
        }
        return params
    }
}

public struct AllOrdersParameters {
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

    func parameters() -> [String: Any] {
        var params: [String: Any] = [:]
        params["page"] = page
        params["limit"] = limit
        if !statuses.isEmpty {
            params["statuses"] = "\(statuses.map({ $0.rawValue }).sorted())"
        }
        if let takerAsset = takerAsset {
            params["takerAsset"] = takerAsset
        }
        if let makerAsset = makerAsset {
            params["makerAsset"] = makerAsset
        }
        return params
    }
}

