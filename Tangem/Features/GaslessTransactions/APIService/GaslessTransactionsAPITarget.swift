//
//  GaslessTransactionsAPITarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

enum GaslessApiTargetConstants {
    // Base URLs
    static let prodBaseURL = URL(string: "https://gasless.tangem.org")!
    static let devBaseURL = URL(string: "https://gasless.tests-d.com")!
    static let stageBaseURL = URL(string: "https://gasless.tests-d.com")!
    static var mockBaseURL: URL { URL(string: "\(WireMockEnvironment.baseURL)/gasless")! }

    // Paths
    static let tokensPath = "/tokens"
    static let signTransactionPath = "/transaction/sign"
    static let signBatchTransactionPath = "/transaction/batch-sign"
    static let feeRecipientPath = "/config/fee-recipient"
    static let tronTokensPath = "/tron/tokens"
    static let tronEstimatePath = "/tron/transaction/estimate"
    static let tronSubmitPath = "/tron/transaction/submit"
}

struct GaslessTransactionsAPITarget: TargetType {
    let apiType: GaslessTransactionsAPIType
    let target: TargetType

    enum TargetType: Equatable {
        case availableTokens
        case sendGaslessTransaction(transaction: GaslessTransactionsDTO.Request.GaslessTransaction)
        case sendGaslessBatchTransaction(transaction: GaslessTransactionsDTO.Request.GaslessBatchTransaction)
        case feeRecipient
        case tronTokens
        case tronEstimate(request: GaslessTransactionsDTO.Request.TronEstimate)
        case tronSubmit(request: GaslessTransactionsDTO.Request.TronSubmit)
    }

    var baseURL: URL {
        let baseUrl: URL

        switch apiType {
        case .prod:
            baseUrl = GaslessApiTargetConstants.prodBaseURL
        case .dev:
            baseUrl = GaslessApiTargetConstants.devBaseURL
        case .stage:
            baseUrl = GaslessApiTargetConstants.stageBaseURL
        case .mock:
            baseUrl = GaslessApiTargetConstants.mockBaseURL
        }

        let versionPath: String
        switch target {
        case .sendGaslessBatchTransaction:
            versionPath = "v2"
        case .availableTokens, .sendGaslessTransaction, .feeRecipient, .tronTokens, .tronEstimate, .tronSubmit:
            versionPath = "v1"
        }

        return baseUrl.appendingPathComponent("api").appendingPathComponent(versionPath)
    }

    var path: String {
        switch target {
        case .availableTokens:
            return GaslessApiTargetConstants.tokensPath
        case .sendGaslessTransaction:
            return GaslessApiTargetConstants.signTransactionPath
        case .sendGaslessBatchTransaction:
            return GaslessApiTargetConstants.signBatchTransactionPath
        case .feeRecipient:
            return GaslessApiTargetConstants.feeRecipientPath
        case .tronTokens:
            return GaslessApiTargetConstants.tronTokensPath
        case .tronEstimate:
            return GaslessApiTargetConstants.tronEstimatePath
        case .tronSubmit:
            return GaslessApiTargetConstants.tronSubmitPath
        }
    }

    var method: Moya.Method {
        switch target {
        case .availableTokens, .feeRecipient, .tronTokens:
            return .get
        case .sendGaslessTransaction, .sendGaslessBatchTransaction, .tronEstimate, .tronSubmit:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .sendGaslessTransaction(let transaction):
            return .requestJSONEncodable(transaction)
        case .sendGaslessBatchTransaction(let transaction):
            return .requestJSONEncodable(transaction)
        case .tronEstimate(let request):
            return .requestJSONEncodable(request)
        case .tronSubmit(let request):
            return .requestJSONEncodable(request)
        case .availableTokens, .feeRecipient, .tronTokens:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        nil
    }
}

// MARK: - TargetTypeLogConvertible protocol conformance

extension GaslessTransactionsAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        true
    }
}
