//
//  ExchangeTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/// Target for finding best quote to exchange and getting data for swap transaction
enum ExchangeTarget {
    /// find the best quote to exchange via 1inch router
    case quote(_ parameters: QuoteParameters)
    /// generate data for calling the 1inch router for exchange
    case swap(_ parameters: ExchangeParameters)
}

extension ExchangeTarget: TargetType {
    var baseURL: URL {
        Constants.exchangeAPIBaseURL
    }

    var path: String {
        switch self {
        case .quote:
            return "/quote"
        case .swap:
            return "/swap"
        }
    }

    var method: Moya.Method { return .get }

    var task: Task {
        switch self {
        case .quote(let parameters):
            return .requestParameters(parameters)
        case .swap(let parameters):
            return .requestParameters(parameters)
        }
    }

    var headers: [String: String]? {
        nil
    }
}
