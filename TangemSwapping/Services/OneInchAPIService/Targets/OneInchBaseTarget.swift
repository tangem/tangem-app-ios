//
//  OneInchBaseTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct OneInchBaseTarget: TargetType {
    let target: TargetType
    let blockchain: SwappingBlockchain
    let oneInchApiKey: String

    var baseURL: URL {
        target.baseURL
    }

    var path: String {
        String(blockchain.chainId) + target.path
    }

    var method: Moya.Method {
        target.method
    }

    var task: Task {
        target.task
    }

    var headers: [String: String]? {
        var headers = target.headers ?? [:]
        headers["Authorization"] = "Bearer \(oneInchApiKey)"
        return headers
    }
}

extension OneInchBaseTarget {
    static let swappingBaseURL = URL(string: "https://api.1inch.dev/swap/v5.2/")!
}
