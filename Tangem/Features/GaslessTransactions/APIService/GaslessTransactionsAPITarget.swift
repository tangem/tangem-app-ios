//
//  GaslessTransactionsAPITarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum GaslessApiTargetConstants {
    // Base URLs
    static let prodBaseURL = URL(string: "https://gasless.tangem.org")!
    static let devBaseURL = URL(string: "https://gasless.tests-d.com")!
    static let stageBaseURL = URL(string: "https://gasless.tests-d.com")!

    // Paths
    static let tokensPath = "/tokens"
    static let signTransactionPath = "/transaction/sign"
    static let feeRecipientPath = "/config/fee-recipient"
}

struct GaslessTransactionsAPITarget: TargetType {
    let apiType: GaslessTransactionsAPIType
    let target: TargetType

    enum TargetType: Equatable {
        case availableTokens
        case sendGaslessTransaction(transaction: GaslessTransactionsDTO.Request.GaslessTransaction)
        case feeRecipient
    }

    // [REDACTED_TODO_COMMENT]
    var baseURL: URL {
        let baseUrl: URL

        switch apiType {
        case .prod:
            baseUrl = GaslessApiTargetConstants.prodBaseURL
        case .dev:
            baseUrl = GaslessApiTargetConstants.devBaseURL
        case .stage:
            baseUrl = GaslessApiTargetConstants.stageBaseURL
        }

        return baseUrl.appendingPathComponent("api").appendingPathComponent("v1")
    }

    var path: String {
        switch target {
        case .availableTokens:
            return GaslessApiTargetConstants.tokensPath
        case .sendGaslessTransaction:
            return GaslessApiTargetConstants.signTransactionPath
        case .feeRecipient:
            return GaslessApiTargetConstants.feeRecipientPath
        }
    }

    var method: Moya.Method {
        switch target {
        case .availableTokens, .feeRecipient:
            return .get
        case .sendGaslessTransaction:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .sendGaslessTransaction(let transaction):
            return .requestJSONEncodable(transaction)
        case .availableTokens, .feeRecipient:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        nil
    }
}
