//
//  MCPConnectionTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import class Foundation.JSONEncoder
import struct Alamofire.HTTPMethod
import Moya

struct MCPConnectionTarget: Moya.TargetType {
    let baseURL: URL
    let path: String
    let method: Alamofire.HTTPMethod
    let task: Moya.Task
    let validationType: Moya.ValidationType
    let headers: [String: String]?

    private init(baseURL: URL, method: Alamofire.HTTPMethod, task: Moya.Task) {
        self.baseURL = baseURL
        path = Self.path
        self.method = method
        self.task = task
        validationType = .successCodes
        headers = ["Content-Type": "application/json"]
    }

    private static let path = "api/authentication/v1/mcp/device_verification"
}

// MARK: - api/authentication/v1/mcp/device_verification

extension MCPConnectionTarget {
    static func get(
        queryParameters: FetchMCPConnectionRequestDTO.Request.QueryParameters,
        baseURL: URL
    ) -> MCPConnectionTarget {
        MCPConnectionTarget(
            baseURL: baseURL,
            method: .get,
            task: .requestParameters(
                parameters: queryParameters.asURLParameters,
                encoding: URLEncoding.queryString
            )
        )
    }

    static func post(
        accept requestBody: MCPConnectionDecisionDTO.Request.Body,
        queryParameters: MCPConnectionDecisionDTO.Request.QueryParameters,
        baseURL: URL,
        encoder: JSONEncoder
    ) throws -> MCPConnectionTarget {
        MCPConnectionTarget(
            baseURL: baseURL,
            method: .post,
            task: .requestCompositeData(
                bodyData: try encoder.encode(requestBody),
                urlParameters: queryParameters.asURLParameters
            )
        )
    }

    static func delete(
        queryParameters: MCPConnectionDecisionDTO.Request.QueryParameters,
        baseURL: URL
    ) -> MCPConnectionTarget {
        MCPConnectionTarget(
            baseURL: baseURL,
            method: .delete,
            task: .requestParameters(parameters: queryParameters.asURLParameters, encoding: URLEncoding.queryString)
        )
    }
}
