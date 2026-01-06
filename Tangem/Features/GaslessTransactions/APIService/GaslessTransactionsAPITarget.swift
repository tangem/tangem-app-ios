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
        case signMetaTransaction(transaction: GaslessTransactionsDTO.Request.MetaTransaction)
    }

    // [REDACTED_TODO_COMMENT]
    var baseURL: URL {
        switch apiType {
        case .prod:
            return URL(string: "https://gasless.tangem.org/api/v1")!
        case .dev:
            return URL(string: "https://gasless.tests-d.com/api/v1")!
        case .stage:
            return URL(string: "https://gasless.tests-s.com/api/v1")!
        }
    }

    var path: String {
        switch target {
        case .availableTokens:
            "/tokens"
        case .signMetaTransaction:
            "/sign"
        }
    }

    var method: Moya.Method {
        switch target {
        case .availableTokens:
            return .get
        case .signMetaTransaction:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .signMetaTransaction(let transaction):
            return .requestJSONEncodable(transaction)
        case .availableTokens:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        nil
    }
}
