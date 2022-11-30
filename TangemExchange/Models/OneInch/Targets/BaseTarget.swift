//
//  BaseTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct BaseTarget: TargetType {
    let target: TargetType
    let blockchain: ExchangeBlockchain

    var baseURL: URL {
        target.baseURL
    }

    var path: String {
        blockchain.id + target.path
    }

    var method: Moya.Method {
        target.method
    }

    var task: Task {
        target.task
    }

    var headers: [String: String]? {
        target.headers
    }
}
