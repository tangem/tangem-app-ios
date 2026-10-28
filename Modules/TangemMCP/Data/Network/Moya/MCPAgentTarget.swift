//
//  MCPAgentTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
public import struct Alamofire.HTTPMethod
public import Moya
public import protocol TangemNetworkUtils.TimeoutIntervalProvider

public struct MCPAgentTarget: Moya.TargetType, TimeoutIntervalProvider {
    public let baseURL: URL
    public let path = "api/authentication/v1/mcp/client"
    public let method = Alamofire.HTTPMethod.get
    public let task: Moya.Task
    public let validationType = Moya.ValidationType.successCodes
    public let headers: [String: String]? = ["Content-Type": "application/json"]
    public let timeoutInterval: TimeInterval? = 10

    init(agentID: String, baseURL: URL) {
        self.baseURL = baseURL
        task = .requestParameters(parameters: ["client_id": agentID], encoding: URLEncoding.queryString)
    }
}
