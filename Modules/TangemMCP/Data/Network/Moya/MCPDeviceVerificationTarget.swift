//
//  MCPDeviceVerificationTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import class Foundation.JSONEncoder
import struct Alamofire.HTTPMethod
import Moya

struct MCPDeviceVerificationTarget: Moya.TargetType {
    let baseURL: URL
    let path = "api/authentication/v1/mcp/device_verification"
    let method: Alamofire.HTTPMethod
    let task: Moya.Task
    let validationType = Moya.ValidationType.successCodes
    let headers: [String: String]? = ["Content-Type": "application/json"]

    private init(baseURL: URL, method: Alamofire.HTTPMethod, task: Moya.Task) {
        self.baseURL = baseURL
        self.method = method
        self.task = task
    }
}

extension MCPDeviceVerificationTarget {
    static func get(
        queryParameters: MCPDeviceVerificationDTO.Get.Request.QueryParameters,
        baseURL: URL
    ) -> MCPDeviceVerificationTarget {
        MCPDeviceVerificationTarget(
            baseURL: baseURL,
            method: Alamofire.HTTPMethod.get,
            task: Moya.Task.requestParameters(
                parameters: queryParameters.asURLParameters,
                encoding: URLEncoding.queryString
            )
        )
    }

    static func post(
        accept requestBody: MCPDeviceVerificationDTO.Post.Request.Body,
        queryParameters: MCPDeviceVerificationDTO.Post.Request.QueryParameters,
        baseURL: URL,
        encoder: JSONEncoder
    ) throws -> MCPDeviceVerificationTarget {
        MCPDeviceVerificationTarget(
            baseURL: baseURL,
            method: Alamofire.HTTPMethod.post,
            task: Moya.Task.requestCompositeData(
                bodyData: try encoder.encode(requestBody),
                urlParameters: queryParameters.asURLParameters
            )
        )
    }

    static func delete(
        queryParameters: MCPDeviceVerificationDTO.Delete.Request.QueryParameters,
        baseURL: URL
    ) -> MCPDeviceVerificationTarget {
        MCPDeviceVerificationTarget(
            baseURL: baseURL,
            method: Alamofire.HTTPMethod.delete,
            task: Moya.Task.requestParameters(parameters: queryParameters.asURLParameters, encoding: URLEncoding.queryString)
        )
    }
}
