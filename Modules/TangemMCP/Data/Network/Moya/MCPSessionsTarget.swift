//
//  MCPSessionsTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import class Foundation.JSONEncoder
import struct Alamofire.HTTPMethod
import Moya

struct MCPSessionsTarget: Moya.TargetType {
    private static let basePath = "api/authentication/v1/mcp/sessions"

    let baseURL: URL
    let path: String
    let method: Alamofire.HTTPMethod
    let task: Moya.Task
    let validationType = Moya.ValidationType.successCodes
    let headers: [String: String]? = ["Content-Type": "application/json"]

    private init(baseURL: URL, path: String, method: Alamofire.HTTPMethod, task: Moya.Task) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.task = task
    }
}

extension MCPSessionsTarget {
    static func get(baseURL: URL) -> MCPSessionsTarget {
        MCPSessionsTarget(
            baseURL: baseURL,
            path: basePath,
            method: Alamofire.HTTPMethod.get,
            task: Moya.Task.requestPlain
        )
    }

    static func delete(sessionID: MCPSession.ID, baseURL: URL) -> MCPSessionsTarget {
        MCPSessionsTarget(
            baseURL: baseURL,
            path: basePath + "/\(sessionID)",
            method: Alamofire.HTTPMethod.delete,
            task: Moya.Task.requestPlain
        )
    }

    static func delete(baseURL: URL) -> MCPSessionsTarget {
        MCPSessionsTarget(
            baseURL: baseURL,
            path: basePath,
            method: Alamofire.HTTPMethod.delete,
            task: Moya.Task.requestPlain
        )
    }

    static func delete(
        queryParameters: MCPSessionsDTO.Delete.Request.QueryParameters,
        baseURL: URL
    ) -> MCPSessionsTarget {
        MCPSessionsTarget(
            baseURL: baseURL,
            path: basePath,
            method: Alamofire.HTTPMethod.delete,
            task: Moya.Task.requestParameters(parameters: queryParameters.asURLParameters, encoding: URLEncoding.queryString)
        )
    }
}
