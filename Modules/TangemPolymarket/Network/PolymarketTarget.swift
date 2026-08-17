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
        }
    }

    var method: Moya.Method {
        .get
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
        }
    }

    var headers: [String: String]? {
        // `api-key` is injected by the caller via `NetworkHeadersPlugin`; nothing target-specific here.
        nil
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
