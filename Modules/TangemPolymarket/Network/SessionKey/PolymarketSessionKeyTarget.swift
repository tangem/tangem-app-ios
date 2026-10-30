//
//  PolymarketSessionKeyTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketSessionKeyTarget: Moya.TargetType {
    let environment: PolymarketBFFEnvironment
    let walletId: String
    let target: Target

    var baseURL: URL { environment.baseURL }
    var headers: [String: String]? { environment.requestHeaders(walletId: walletId) }

    enum Target {
        case sessionKeys
        case authorize(PolymarketDTO.SessionKeyAuthorizationRequest)
        case revoke(PolymarketDTO.SessionKeyRevocationRequest)
        case setEnabled(sessionKeyAddress: String, PolymarketDTO.SessionKeyEnabledRequest)
    }

    var path: String {
        switch target {
        case .sessionKeys:
            "api/predictions/v1/wallet"
        case .authorize:
            "api/predictions/v1/wallet/session-keys"
        case .revoke:
            "api/predictions/v1/wallet/session-keys/revocations"
        case .setEnabled(let sessionKeyAddress, _):
            "api/predictions/v1/wallet/session-keys/\(sessionKeyAddress)/enabled"
        }
    }

    var method: Moya.Method {
        switch target {
        case .sessionKeys: .get
        case .authorize, .revoke: .post
        case .setEnabled: .put
        }
    }

    var task: Moya.Task {
        switch target {
        case .sessionKeys:
            .requestParameters(parameters: ["walletId": walletId], encoding: URLEncoding.queryString)
        case .authorize(let request):
            .requestJSONEncodable(request)
        case .revoke(let request):
            .requestJSONEncodable(request)
        case .setEnabled(_, let request):
            .requestJSONEncodable(request)
        }
    }
}

extension PolymarketSessionKeyTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
