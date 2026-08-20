//
//  PolymarketWalletTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketWalletTarget: Moya.TargetType {
    let baseURL: URL
    let target: Target

    enum Target {
        case walletState(ownerAddress: String)
        case deploy(PolymarketDTO.DeployRequest)
        case approvals(PolymarketDTO.ApprovalsRequest)
    }

    var path: String {
        switch target {
        case .walletState:
            return "api/predictions/v1/wallet"
        case .deploy:
            return "api/predictions/v1/wallet/deploy"
        case .approvals:
            return "api/predictions/v1/wallet/approvals"
        }
    }

    var method: Moya.Method {
        switch target {
        case .walletState: .get
        case .deploy, .approvals: .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .walletState(let ownerAddress):
            return .requestParameters(parameters: ["ownerAddress": ownerAddress], encoding: URLEncoding.queryString)
        case .deploy(let request):
            return .requestJSONEncodable(request)
        case .approvals(let request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        // `api-key` is injected by the caller via `NetworkHeadersPlugin`; nothing target-specific here.
        nil
    }
}

extension PolymarketWalletTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
