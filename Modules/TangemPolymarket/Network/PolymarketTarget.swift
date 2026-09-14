//
//  PolymarketTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketTarget: Moya.TargetType {
    let baseURL: URL
    let target: Target

    enum Target {
        case categories(locale: String?)
        case events(PolymarketEventsRequest)
        case event(id: String)
        case search(PolymarketSearchRequest)
        case series
        case seriesEvents(seriesId: String)
        case orderQuote(PolymarketDTO.OrderQuoteRequestBody)
        case positions(PolymarketPositionsRequest)
    }

    var path: String {
        switch target {
        case .categories:
            return "api/predictions/v1/categories"
        case .events:
            return "api/predictions/v1/events"
        case .event(let id):
            return "api/predictions/v1/events/\(id)"
        case .search:
            return "api/predictions/v1/search"
        case .series:
            return "api/predictions/v1/series"
        case .seriesEvents(let seriesId):
            return "api/predictions/v1/series/\(seriesId)/events"
        case .orderQuote:
            return "api/predictions/v1/orders/quote"
        case .positions:
            return "api/predictions/v1/positions"
        }
    }

    var method: Moya.Method {
        switch target {
        case .categories, .events, .event, .search, .series, .seriesEvents, .positions:
            return .get
        case .orderQuote:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .categories(let locale):
            var parameters: [String: Any] = [:]
            if let locale {
                parameters["locale"] = locale
            }
            return parameters.isEmpty ? .requestPlain : .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)

        case .events(let request):
            var parameters: [String: Any] = [:]
            if let category = request.category {
                parameters["category"] = category
            }
            if let sort = request.sort {
                parameters["sort"] = sort.rawValue
            }
            if let ascending = request.ascending {
                parameters["ascending"] = ascending
            }
            if let limit = request.limit {
                parameters["limit"] = limit
            }
            if let cursor = request.cursor {
                parameters["cursor"] = cursor
            }
            return parameters.isEmpty
                ? .requestPlain
                : .requestParameters(parameters: parameters, encoding: URLEncoding(boolEncoding: .literal))

        case .event:
            return .requestPlain

        case .search(let request):
            var parameters: [String: Any] = [:]
            parameters["query"] = request.query
            if let limit = request.limit {
                parameters["limit"] = limit
            }
            if let page = request.page {
                parameters["page"] = page
            }
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)

        case .series:
            return .requestPlain

        case .seriesEvents:
            return .requestPlain

        case .orderQuote(let body):
            return .requestJSONEncodable(body)

        case .positions(let request):
            return .requestParameters(
                parameters: [
                    "depositWalletAddress": request.depositWalletAddress,
                    "sort": request.sort.rawValue,
                    "ascending": request.ascending,
                    "limit": request.limit,
                    "offset": request.offset,
                ],
                encoding: URLEncoding(boolEncoding: .literal)
            )
        }
    }

    var headers: [String: String]? {
        switch target {
        case .positions(let request):
            return [Constants.walletIdHeader: request.walletId]
        case .categories, .events, .event, .search, .series, .seriesEvents, .orderQuote:
            return nil
        }
    }
}

// MARK: - Constants

private extension PolymarketTarget {
    enum Constants {
        static let walletIdHeader = "wallet-id"
    }
}

extension PolymarketTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
