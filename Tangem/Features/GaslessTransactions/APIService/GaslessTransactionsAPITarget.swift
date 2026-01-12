//
//  GaslessTransactionsAPITarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct GaslessTransactionsAPITarget: TargetType {
    let apiType: GaslessTransactionsAPIType
    let target: TargetType

    enum TargetType: Equatable {
        case availableTokens
        case signGaslessTransaction(transaction: GaslessTransactionsDTO.Request.GaslessTransaction)
    }

    // [REDACTED_TODO_COMMENT]
    var baseURL: URL {
        switch apiType {
        case .prod:
            return URL(string: "https://gasless.tests-d.com/api/v1")!
        case .dev:
            return URL(string: "https://gasless.tests-d.com/api/v1")!
        case .stage:
            return URL(string: "https://gasless.tests-d.com/api/v1")!
        }
    }

    var path: String {
        switch target {
        case .availableTokens:
            "/tokens"
        case .signGaslessTransaction:
            "/sign"
        }
    }

    var method: Moya.Method {
        switch target {
        case .availableTokens:
            return .get
        case .signGaslessTransaction:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .signGaslessTransaction(let transaction):
            return .requestJSONEncodable(transaction)
        case .availableTokens:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        nil
    }
}
