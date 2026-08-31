//
//  PolymarketDepositWalletTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketDepositWalletTarget: Moya.TargetType {
    let baseURL: URL
    let target: Target
    let headers: [String: String]?

    enum Target {
        case walletState(ownerAddress: String?, walletId: String)
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
        case .walletState(let ownerAddress, let walletId):
            let parameters = ownerAddress.map { ["ownerAddress": $0] } ?? ["walletId": walletId]

            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        case .deploy(let request):
            return .requestJSONEncodable(request)
        case .approvals(let request):
            return .requestJSONEncodable(request)
        }
    }
}

extension PolymarketDepositWalletTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
