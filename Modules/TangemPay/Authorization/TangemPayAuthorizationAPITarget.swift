//
//  TangemPayAuthorizationAPITarget.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct TangemPayAuthorizationAPITarget: TargetType {
    let target: Target
    let apiType: VisaAPIType

    var baseURL: URL {
        apiType.baseURL.appendingPathComponent("auth")
    }

    var path: String {
        switch target {
        case .getChallenge:
            return "challenge"
        case .getTokens:
            return "token"
        case .refreshTokens:
            return "token/refresh"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getChallenge,
             .getTokens,
             .refreshTokens:
            return .post
        }
    }

    var task: Moya.Task {
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

    var headers: [String: String]? {
        nil
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
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
