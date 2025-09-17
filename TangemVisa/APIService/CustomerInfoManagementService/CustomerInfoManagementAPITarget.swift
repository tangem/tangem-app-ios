//
//  CustomerInfoManagementAPITarget.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct CustomerInfoManagementAPITarget: TargetType {
    let authorizationToken: String
    let target: Target
    let apiType: VisaAPIType

    var baseURL: URL {
        apiType.baseURL.appendingPathComponent("customer/")
    }

    var path: String {
        switch target {
        case .getCustomerInfo:
            return "me"
        case .getKYCAccessToken:
            return "kyc"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getCustomerInfo,
             .getKYCAccessToken:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .getCustomerInfo, .getKYCAccessToken:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        var defaultHeaders = VisaConstants.defaultHeaderParams
        defaultHeaders[VisaConstants.authorizationHeaderKey] = authorizationToken

        return defaultHeaders
    }
}

extension CustomerInfoManagementAPITarget {
    enum Target {
        /// Load all available customer info. Can be used for loading data about payment account address
        /// Will be updated later, not fully implemented on BFF
        case getCustomerInfo

        /// Retrieves an access token for the SumSub KYC flow
        case getKYCAccessToken
    }
}

import TangemNetworkUtils

extension CustomerInfoManagementAPITarget: TargetTypeLogConvertible {
    var shouldLogResponseBody: Bool {
        switch target {
        case .getCustomerInfo:
            true
        default:
            false
        }
    }

    var requestDescription: String {
        switch target {
        case .getCustomerInfo:
            "customer/me [\(curlString(url: baseURL.appendingPathComponent(path).absoluteString, method: method.rawValue, headers: headers ?? [:], body: nil))]"
        default:
            ""
        }
    }
}

func curlString(
    url: String,
    method: String = "GET",
    headers: [String: String] = [:],
    body: Data? = nil
) -> String {
    // Start with method and URL
    var components = ["curl -X \(method) \"\(url)\""]

    // Add headers
    let headerString = headers.map { key, value in
        #"-H "\#(key): \#(value)""#
    }.joined(separator: " ")

    if !headerString.isEmpty {
        components.append(headerString)
    }

    // Add body if present
    if let body = body, let bodyString = String(data: body, encoding: .utf8) {
        let escapedBody = bodyString
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "")
        components.append("-d \"\(escapedBody)\"")
    }

    return components.joined(separator: " ")
}
