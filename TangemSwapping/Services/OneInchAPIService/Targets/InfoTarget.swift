//
//  InfoTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/// Target for getting the list of sources for swapping, getting list of available tokens and getting gas presets
enum InfoTarget {
    /// List of sources that are available for swap
    case liquiditySources
    /// List of tokens that are available for swap
    case tokens
    /// List of presets configurations for the 1inch router
    case presets
}

extension InfoTarget: TargetType {
    var baseURL: URL {
        OneInchBaseTarget.swappingBaseURL
    }

    var path: String {
        switch self {
        case .liquiditySources:
            return "/liquidity-sources"
        case .tokens:
            return "/tokens"
        case .presets:
            return "/presets"
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
