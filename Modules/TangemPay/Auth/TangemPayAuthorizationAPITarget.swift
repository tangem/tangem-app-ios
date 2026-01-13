//
//  TangemPayAuthorizationAPITarget.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

public struct TangemPayAuthorizationAPITarget: TargetType {
    let target: Target
    let apiType: TangemPayAPIType

    public var baseURL: URL {
        apiType.baseURL.appendingPathComponent("auth")
    }

    public var path: String {
        switch target {
        case .getChallenge:
            return "challenge"
        case .getTokens:
            return "token"
        case .refreshTokens:
            return "token/refresh"
        }
    }

    public var method: Moya.Method {
        switch target {
        case .getChallenge,
             .getTokens,
             .refreshTokens:
            return .post
        }
    }

    public var task: Moya.Task {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let encodable: Encodable
        switch target {
        case .getChallenge(let request):
            encodable = request
        case .getTokens(let request):
            encodable = request
        case .refreshTokens(let request):
            encodable = request
        }
        return .requestCustomJSONEncodable(encodable, encoder: jsonEncoder)
    }

    public var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}

extension TangemPayAuthorizationAPITarget {
    enum Target {
        case getChallenge(TangemPayGetChallengeRequest)
        case getTokens(TangemPayGetTokensRequest)
        case refreshTokens(TangemPayRefreshTokensRequest)
    }
}

extension TangemPayAuthorizationAPITarget: TargetTypeLogConvertible {
    public var requestDescription: String {
        path
    }

    public var shouldLogResponseBody: Bool {
        false
    }
}
