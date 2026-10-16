//
//  SocialAuthTarget.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct SocialAuthTarget: Moya.TargetType {
    let baseURL: URL
    let endpoint: Endpoint

    enum Endpoint {
        case recoverWallet(request: RecoverWalletDTO.Request)
        case recoveryPublicKey
    }

    private static let pathPrefix = "api/authentication/v1/mobile/wallet/"

    var path: String {
        switch endpoint {
        case .recoverWallet:
            return Self.pathPrefix + "recover"
        case .recoveryPublicKey:
            return Self.pathPrefix + "recovery-public-key"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .recoverWallet:
            return .post
        case .recoveryPublicKey:
            return .get
        }
    }

    var validationType: Moya.ValidationType {
        .successCodes
    }

    var task: Moya.Task {
        switch endpoint {
        case .recoverWallet(let request):
            return .requestJSONEncodable(request)
        case .recoveryPublicKey:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        nil
    }
}

extension SocialAuthTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
