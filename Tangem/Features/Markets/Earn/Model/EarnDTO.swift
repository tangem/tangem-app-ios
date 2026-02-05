//
//  EarnDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum EarnDTO {
    enum List {}
    enum Networks {}
}

// MARK: - List

extension EarnDTO.List {
    struct Request: Encodable {
        let isForEarn: Bool?
        let page: Int?
        let limit: Int?
        let type: EarnType?
        let networkIds: [String]?

        var parameters: [String: Any] {
            var params: [String: Any] = [:]

            if let isForEarn {
                params["isForEarn"] = isForEarn ? "true" : "false"
            }
            if let page {
                params["page"] = page
            }
            if let limit {
                params["limit"] = limit
            }
            if let type {
                params["type"] = type.rawValue
            }
            if let networkIds, !networkIds.isEmpty {
                params["networkIds"] = networkIds.joined(separator: ",")
            }

            return params
        }
    }

    enum EarnType: String, Encodable {
        case staking
        case yield
    }

    struct Response: Decodable {
        let items: [Item]
        let meta: Meta
    }

    struct Meta: Decodable {
        let page: Int
        let limit: Int
    }

    struct Item: Decodable {
        let apy: String
        let networkId: String
        let rewardType: String
        let type: String
        let token: Token
    }

    struct Token: Decodable {
        let id: String
        let symbol: String
        let name: String
        let address: String?
        let decimalCount: Int?
    }
}

// MARK: - Networks

extension EarnDTO.Networks {
    struct Request: Encodable {
        let type: EarnDTO.List.EarnType?

        var parameters: [String: Any] {
            var params: [String: Any] = [:]

            if let type {
                params["type"] = type.rawValue
            }

            return params
        }
    }

    struct Response: Decodable {
        let items: [Item]
    }

    struct Item: Decodable {
        let networkId: String
    }
}
