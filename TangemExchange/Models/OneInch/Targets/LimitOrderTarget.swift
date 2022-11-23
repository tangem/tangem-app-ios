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
    case append(blockchain: ExchangeBlockchain, order: LimitOrder)
    // GET
    case ordersForAddress(blockchain: ExchangeBlockchain, parameters: OrdersForAddressParameters)
    case allOrders(blockchain: ExchangeBlockchain, parameters: AllOrdersParameters)
    case countOrders(blockchain: ExchangeBlockchain, statuses: [ExchangeOrderStatus])
    case events(blockchain: ExchangeBlockchain, limit: Int)
    case eventsForOrder(blockchain: ExchangeBlockchain, orderHash: String)
    case hasActiveOrdersWithPermit(blockchain: ExchangeBlockchain, walletAddress: String, tokenAddress: String)
}

extension LimitOrderTarget: TargetType {
    var baseURL: URL {
        Constants.limitAPIBaseURL
    }

    var path: String {
        switch self {
        case .append(let blockchain, _):
            return "/\(blockchain.id)/limit-order"
        case .ordersForAddress(let blockchain, let parameters):
            return "/\(blockchain.id)/limit-order/address/\(parameters.address)"
        case .allOrders(let blockchain, _):
            return "/\(blockchain.id)/limit-order/all"
        case .countOrders(let blockchain, _):
            return "/\(blockchain.id)/limit-order/count"
        case .events(let blockchain, _):
            return "/\(blockchain.id)/limit-order/events"
        case .eventsForOrder(let blockchain, let orderHash):
            return "/\(blockchain.id)/limit-order/events/\(orderHash)"
        case .hasActiveOrdersWithPermit(let blockchain, let walletAddress, let tokenAddress):
            return "/\(blockchain.id)/limit-order/has-active-orders-with-permit/\(walletAddress)/\(tokenAddress)"
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
        case .append(_, let order):
            return .requestJSONEncodable(order)
        case .ordersForAddress(_, let parameters):
            return .requestParameters(parameters: parameters.parameters(), encoding: URLEncoding())
        case .allOrders(_, let parameters):
            return .requestParameters(parameters: parameters.parameters(), encoding: URLEncoding())
        case .countOrders(_, let parameters):
            let statuses = "\(parameters.map({ $0.rawValue }).sorted())"
            return .requestParameters(parameters: ["statuses": statuses], encoding: URLEncoding())
        case .events(_, let limit):
            return .requestParameters(parameters: ["limit": limit], encoding: URLEncoding())
        case .eventsForOrder, .hasActiveOrdersWithPermit:
            return .requestPlain
        }
    }

    var headers: [String: String]? { return nil }
}
