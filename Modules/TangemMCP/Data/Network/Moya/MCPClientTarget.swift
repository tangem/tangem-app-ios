//
//  MCPClientTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct Alamofire.HTTPMethod
import Moya
import protocol TangemNetworkUtils.TimeoutIntervalProvider

struct MCPClientTarget: Moya.TargetType, TimeoutIntervalProvider {
    let baseURL: URL
    let path = "api/authentication/v1/mcp/client"
    let method: Alamofire.HTTPMethod
    let task: Moya.Task
    let validationType = Moya.ValidationType.successCodes
    let headers: [String: String]? = ["Content-Type": "application/json"]
    let timeoutInterval: TimeInterval? = 10

    private init(baseURL: URL, method: Alamofire.HTTPMethod, task: Moya.Task) {
        self.baseURL = baseURL
        self.method = method
        self.task = task
    }
}

extension MCPClientTarget {
    static func get(agentID: String, baseURL: URL) -> MCPClientTarget {
        MCPClientTarget(
            baseURL: baseURL,
            method: Alamofire.HTTPMethod.get,
            task: Moya.Task.requestParameters(parameters: ["client_id": agentID], encoding: URLEncoding.queryString)
        )
    }
}
