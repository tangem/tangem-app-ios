//
//  MCPTransactionIntentTarget.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct Alamofire.HTTPMethod
import Moya

struct MCPTransactionIntentTarget: Moya.TargetType {
    let baseURL: URL
    let path: String
    let method: Alamofire.HTTPMethod
    let task: Moya.Task
    let validationType: Moya.ValidationType
    let headers: [String: String]?

    private init(baseURL: URL, path: String, method: Alamofire.HTTPMethod, task: Moya.Task) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.task = task
        validationType = .successCodes
        headers = nil
    }
}

// MARK: - api/transactions/v1/intents/{intentId}

extension MCPTransactionIntentTarget {
    static func get(intentId: String, baseURL: URL) -> MCPTransactionIntentTarget {
        MCPTransactionIntentTarget(
            baseURL: baseURL,
            path: "api/transactions/v1/intents/\(intentId)",
            method: .get,
            task: .requestPlain
        )
    }
}

// MARK: - api/transactions/v1/intents/{intentId}/transaction

extension MCPTransactionIntentTarget {
    static func reportTransaction(
        intentId: String,
        requestBody: ReportMCPSendIntentTransactionDTO.Request,
        baseURL: URL
    ) -> MCPTransactionIntentTarget {
        MCPTransactionIntentTarget(
            baseURL: baseURL,
            path: "api/transactions/v1/intents/\(intentId)/transaction",
            method: .post,
            task: .requestJSONEncodable(requestBody)
        )
    }
}
