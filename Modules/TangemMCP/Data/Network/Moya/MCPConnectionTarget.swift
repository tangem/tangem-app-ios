//
//  MCPConnectionTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.URL
public import class Foundation.JSONEncoder
public import struct Alamofire.HTTPMethod
public import Moya

public struct MCPConnectionTarget: Moya.TargetType {
    public let baseURL: URL
    public let path: String
    public let method: Alamofire.HTTPMethod
    public let task: Moya.Task
    public let validationType: Moya.ValidationType
    public let headers: [String: String]?

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
