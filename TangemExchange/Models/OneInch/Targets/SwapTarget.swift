//
//  SwapTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/// Target for finding best quote to exchange and getting data for swap transaction
enum SwapTarget {
    /// find the best quote to exchange via 1inch router
    case quote(blockchain: ExchangeBlockchain, parameters: QuoteParameters)
    /// generate data for calling the 1inch router for exchange
    case swap(blockchain: ExchangeBlockchain, parameters: SwapParameters)
}

extension SwapTarget: TargetType {
    var baseURL: URL {
        Constants.exchangeAPIBaseURL
    }

    var path: String {
        switch self {
        case let .quote(blockchain, _):
            return "/\(blockchain.id)/quote"
        case let .swap(blockchain, _):
            return "/\(blockchain.id)/swap"
        }
    }

    var method: Moya.Method { return .get }

    var task: Task {
        switch self {
        case let .quote(_, parameters):
            return .requestParameters(parameters: parameters.parameters(), encoding: URLEncoding())
        case let .swap(_, parameters):
            return .requestParameters(parameters: parameters.parameters(), encoding: URLEncoding())
        }
    }

    var headers: [String: String]? {
        nil
    }
}
