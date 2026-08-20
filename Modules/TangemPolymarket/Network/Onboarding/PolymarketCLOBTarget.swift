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
    let authHeaders: PolymarketCLOBAuthHeaders

    enum Target {
        case createCredentials
        case deriveCredentials
        case updateBalanceAllowance
        case balanceAllowance
    }

    var path: String {
        switch target {
        case .createCredentials: "auth/api-key"
        case .deriveCredentials: "auth/derive-api-key"
        case .updateBalanceAllowance: "balance-allowance/update"
        case .balanceAllowance: "balance-allowance"
        }
    }

    var method: Moya.Method {
        switch target {
        case .createCredentials: .post
        case .deriveCredentials, .updateBalanceAllowance, .balanceAllowance: .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .createCredentials, .deriveCredentials:
            return .requestPlain
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
        authHeaders.values
    }
}

private extension PolymarketCLOBTarget {
    enum Constants {
        static let assetTypeKey = "asset_type"
        static let signatureTypeKey = "signature_type"
        static let collateralAssetType = "COLLATERAL"

        static let poly1271SignatureType = 3
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
