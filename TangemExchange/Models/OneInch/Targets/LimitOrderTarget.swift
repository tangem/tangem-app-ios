//
//  LimitOrderTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum LimitOrderTarget {
    // POST
    case append(_ order: LimitOrder)
    // GET
    case ordersForAddress(_ parameters: OrdersForAddressParameters)
    case allOrders(_ parameters: AllOrdersParameters)
    case countOrders(_ statuses: [ExchangeOrderStatus])
    case events(_ limit: Int)
    case eventsForOrder(_ orderHash: String)
    case hasActiveOrdersWithPermit(walletAddress: String, tokenAddress: String)
}

extension LimitOrderTarget: TargetType {
    var baseURL: URL {
        Constants.limitAPIBaseURL
    }

    var path: String {
        switch self {
        case .append:
            return "/limit-order"
        case .ordersForAddress(let parameters):
            return "/limit-order/address/\(parameters.address)"
        case .allOrders:
            return "/limit-order/all"
        case .countOrders:
            return "/limit-order/count"
        case .events:
            return "/limit-order/events"
        case .eventsForOrder(let orderHash):
            return "/limit-order/events/\(orderHash)"
        case .hasActiveOrdersWithPermit(let walletAddress, let tokenAddress):
            return "/limit-order/has-active-orders-with-permit/\(walletAddress)/\(tokenAddress)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .append:
            return .post
        case .ordersForAddress, .allOrders, .countOrders, .events, .eventsForOrder, .hasActiveOrdersWithPermit:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .append(let order):
            return .requestJSONEncodable(order)
        case .ordersForAddress(let parameters):
            return .requestParameters(parameters)
        case .allOrders(let parameters):
            return .requestParameters(parameters)
        case .countOrders(let parameters):
            let statuses = "\(parameters.map { $0.rawValue }.sorted())"
            return .requestParameters(parameters: ["statuses": statuses], encoding: URLEncoding())
        case .events(let limit):
            return .requestParameters(parameters: ["limit": limit], encoding: URLEncoding())
        case .eventsForOrder, .hasActiveOrdersWithPermit:
            return .requestPlain
        }
    }

    var headers: [String: String]? { return nil }
}
