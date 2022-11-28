//
//  InfoTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/// Target for getting the list of sources for exchange, getting list of available tokens and getting gas presets
enum InfoTarget {
    /// List of sources that are available for swap
    case liquiditySources(blockchain: ExchangeBlockchain)
    /// List of tokens that are available for swap
    case tokens(blockchain: ExchangeBlockchain)
    /// List of presets configurations for the 1inch router
    case presets(blockchain: ExchangeBlockchain)
}

extension InfoTarget: TargetType {
    var baseURL: URL {
        Constants.exchangeAPIBaseURL
    }

    var path: String {
        switch self {
        case .liquiditySources(let blockchain):
            return "/\(blockchain.id)/liquidity-sources"
        case .tokens(let blockchain):
            return "/\(blockchain.id)/tokens"
        case .presets(let blockchain):
            return "/\(blockchain.id)/presets"
        }
    }

    var method: Moya.Method { return .get }

    var task: Task {
        .requestPlain
    }

    var headers: [String: String]? {
        nil
    }
}
