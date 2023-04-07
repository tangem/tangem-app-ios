//
//  SwappingTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/// Target for finding best quote to swapping and getting data for swap transaction
enum SwappingTarget {
    /// find the best quote to swapping via 1inch router
    case quote(_ parameters: QuoteParameters)
    /// generate data for calling the 1inch router for swapping
    case swap(_ parameters: SwappingParameters)
}

extension SwappingTarget: TargetType {
    var baseURL: URL {
        OneInchBaseTarget.swappingBaseURL
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
