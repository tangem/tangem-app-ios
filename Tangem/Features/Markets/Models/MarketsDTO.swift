//
//  MarketsDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsDTO {
    enum General {}
    enum ChartsHistory {}
}

// MARK: - General

extension MarketsDTO.General {
    enum Order: String, Encodable {
        case rating
        case trending
        case buyers
        case gainers
        case losers
        case category

        init(_ orderType: MarketsListOrderType) {
            switch orderType {
            case .rating: self = .rating
            case .trending: self = .trending
            case .buyers: self = .buyers
            case .gainers: self = .gainers
            case .losers: self = .losers
            }
        }
    }

    struct Request: Encodable {
        let currency: String
        let offset: Int
        let limit: Int
        let interval: MarketsPriceIntervalType
        let order: Order
        let search: String?
        let showNetworks: Bool?
        let categoryId: Int?
        let sectorId: Int?
        let geckoCategoryId: String?
        let country: String?

        init(
            currency: String,
            offset: Int = 0,
            limit: Int = 20,
            interval: MarketsPriceIntervalType,
            order: Order,
            search: String?,
            showNetworks: Bool?,
            categoryId: Int? = nil,
            sectorId: Int? = nil,
            geckoCategoryId: String? = nil,
            country: String? = nil
        ) {
            self.currency = currency
            self.offset = offset
            self.limit = limit
            self.interval = interval
            self.order = order
            self.search = search
            self.showNetworks = showNetworks
            self.categoryId = categoryId
            self.sectorId = sectorId
            self.geckoCategoryId = geckoCategoryId
            self.country = country
        }

        // MARK: - Helper

        var parameters: [String: Any] {
            var params: [String: Any] = [
                "currency": currency,
                "offset": offset,
                "limit": limit,
                "interval": interval.marketsListId,
                "order": order.rawValue,
            ]

            if let search, !search.isEmpty {
                params["search"] = search
            }

            if let showNetworks {
                params["showNetworks"] = showNetworks ? "true" : "false"
            }

            if let categoryId {
                params["categoryId"] = categoryId
            }

            if let sectorId {
                params["sectorId"] = sectorId
            }

            if let geckoCategoryId, !geckoCategoryId.isEmpty {
                params["geckoCategoryId"] = geckoCategoryId
            }

            if let country, !country.isEmpty {
                params["country"] = country
            }

            return params
        }
    }

    struct Response: Decodable {
        let tokens: [MarketsTokenModel]
        let total: Int
        let limit: Int
        let offset: Int
        let summary: MarketsTokensSummary?
    }
}

// MARK: - HistoryPreview

extension MarketsDTO.ChartsHistory {
    typealias PreviewResponse = [String: MarketsChartModel]
    typealias HistoryResponse = MarketsChartModel

    struct PreviewRequest: Encodable {
        let currency: String
        let coinIds: [String]
        let interval: MarketsPriceIntervalType

        init(
            currency: String,
            coinIds: [String],
            interval: MarketsPriceIntervalType
        ) {
            self.currency = currency
            self.coinIds = coinIds
            self.interval = interval
        }

        // MARK: - Helper

        var parameters: [String: Any] {
            [
                "currency": currency,
                "coin_ids": coinIds.joined(separator: ","),
                "interval": interval.marketsListId,
            ]
        }
    }

    struct HistoryRequest: Encodable {
        let currency: String
        let tokenId: TokenItemId
        let interval: MarketsPriceIntervalType
    }
}
