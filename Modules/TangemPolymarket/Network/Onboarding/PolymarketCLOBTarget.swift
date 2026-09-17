//
//  PolymarketCLOBTarget.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct PolymarketCLOBTarget: Moya.TargetType {
    let baseURL: URL
    let target: Target
    let authHeaders: [String: String]

    enum Target {
        case createCredentials
        case deriveCredentials
        case updateBalanceAllowance
        case balanceAllowance
        case placeOrder(body: Data)
        case order(id: String)
    }

    var path: String {
        String(signedPath.dropFirst())
    }

    var signedPath: String {
        switch target {
        case .createCredentials: "/auth/api-key"
        case .deriveCredentials: "/auth/derive-api-key"
        case .updateBalanceAllowance: "/balance-allowance/update"
        case .balanceAllowance: "/balance-allowance"
        case .placeOrder: "/order"
        case .order(let id): "/data/order/\(id)"
        }
    }

    var method: Moya.Method {
        switch target {
        case .createCredentials, .placeOrder: .post
        case .deriveCredentials, .updateBalanceAllowance, .balanceAllowance, .order: .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .createCredentials, .deriveCredentials, .order:
            return .requestPlain
        case .placeOrder(let body):
            return .requestData(body)
        case .updateBalanceAllowance, .balanceAllowance:
            return .requestParameters(
                parameters: [
                    Constants.assetTypeKey: Constants.collateralAssetType,
                    Constants.signatureTypeKey: Constants.poly1271SignatureType,
                ],
                encoding: URLEncoding.queryString
            )
        }
    }

    var headers: [String: String]? {
        switch target {
        case .placeOrder:
            return authHeaders.merging(Constants.jsonHeaders) { current, _ in current }
        case .createCredentials, .deriveCredentials, .updateBalanceAllowance, .balanceAllowance, .order:
            return authHeaders
        }
    }
}

private extension PolymarketCLOBTarget {
    enum Constants {
        static let assetTypeKey = "asset_type"
        static let signatureTypeKey = "signature_type"
        static let collateralAssetType = "COLLATERAL"

        static let poly1271SignatureType = 3

        static let jsonHeaders = ["Content-Type": "application/json"]
    }
}

extension PolymarketCLOBTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        false
    }
}
