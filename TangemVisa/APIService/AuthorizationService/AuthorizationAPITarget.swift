//
//  AuthorizationAPITarget.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import Moya
import TangemPay

struct AuthorizationAPITarget: TargetType {
    let target: Target
    let apiType: VisaAPIType

    var baseURL: URL {
        apiType.bffBaseURL.appendingPathComponent("auth")
    }

    var path: String {
        switch target {
        case .generateNonce:
            return "challenge"
        case .getAuthorizationTokens:
            return "token"
        case .refreshAuthorizationTokens:
            return "token/refresh"
        case .exchangeAuthorizationTokens:
            return "token/exchange"
        }
    }

    var method: Moya.Method {
        switch target {
        case .generateNonce,
             .getAuthorizationTokens,
             .refreshAuthorizationTokens,
             .exchangeAuthorizationTokens:
            return .post
        }
    }

    var task: Moya.Task {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let encodable: Encodable
        switch target {
        case .generateNonce(let request):
            encodable = request
        case .getAuthorizationTokens(let request):
            encodable = request
        case .refreshAuthorizationTokens(let request):
            encodable = request
        case .exchangeAuthorizationTokens(let request):
            encodable = request
        }
        return .requestCustomJSONEncodable(encodable, encoder: jsonEncoder)
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}

extension AuthorizationAPITarget {
    struct GenerateNonceRequestDTO: Encodable {
        let cardId: String?
        let cardPublicKey: String?
        let cardWalletAddress: String?
        let customerWalletAddress: String?
        let authType: VisaAuthorizationType
    }

    struct GetAuthorizationTokensRequestDTO: Encodable {
        let signature: String
        let salt: String?
        let sessionId: String
        let authType: VisaAuthorizationType
        let messageFormat: String?
    }

    struct RefreshAuthoriationTokensRequestDTO: Encodable {
        let refreshToken: String
        let authType: VisaAuthorizationType
    }
}

extension AuthorizationAPITarget {
    enum Target {
        /// Two types of nonce can be requested:
        /// 1. `card_id` - nonce for card that didn't finish activation process
        /// 2. `card_wallet` - nonce for activated card
        /// Signed nonce used for retreiving authorization tokens
        case generateNonce(request: GenerateNonceRequestDTO)
        /// Two types of tokens can be retreived:
        /// 1. `card_id` - this access token can be using for activation process
        /// 2. `card_wallet` - this access token provides access to transaction history and some customer info
        case getAuthorizationTokens(request: GetAuthorizationTokensRequestDTO)
        /// Refresh staled access token
        case refreshAuthorizationTokens(request: RefreshAuthoriationTokensRequestDTO)
        /// Change activation process authorization tokens to activated authorization tokens
        case exchangeAuthorizationTokens(request: AuthorizationTokenDTO)
    }
}

extension AuthorizationAPITarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        return false
    }
}
