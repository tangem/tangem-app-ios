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
        case updateBalanceAllowance(PolymarketBalanceAllowanceAsset)
        case balanceAllowance
        case placeOrder(body: Data)
        case order(id: String)
        case price(tokenId: String, orderSide: PolymarketOrderSide)
        case priceHistory(tokenId: String, query: PolymarketPriceHistoryQuery)
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
        case .price: "/price"
        case .priceHistory: "/prices-history"
        }
    }

    var method: Moya.Method {
        switch target {
        case .createCredentials,
             .placeOrder:
            .post
        case .deriveCredentials,
             .updateBalanceAllowance,
             .balanceAllowance,
             .order,
             .price,
             .priceHistory:
            .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .createCredentials, .deriveCredentials, .order:
            return .requestPlain
        case .placeOrder(let body):
            return .requestData(body)
        case .price(let tokenId, let orderSide):
            return .requestParameters(
                parameters: [Constants.tokenIdKey: tokenId, Constants.sideKey: orderSide.matchingBookSide.rawValue],
                encoding: URLEncoding.queryString
            )
        case .priceHistory(let tokenId, let query):
            return .requestParameters(parameters: Self.parameters(tokenId: tokenId, query: query), encoding: URLEncoding.queryString)
        case .updateBalanceAllowance(let asset):
            return .requestParameters(parameters: Self.parameters(for: asset), encoding: URLEncoding.queryString)
        case .balanceAllowance:
            return .requestParameters(parameters: Self.parameters(for: .collateral), encoding: URLEncoding.queryString)
        }
    }

    var headers: [String: String]? {
        switch target {
        case .placeOrder:
            return authHeaders.merging(Constants.jsonHeaders) { current, _ in current }
        case .createCredentials,
             .deriveCredentials,
             .updateBalanceAllowance,
             .balanceAllowance,
             .order,
             .price,
             .priceHistory:
            return authHeaders
        }
    }
}

private extension PolymarketCLOBTarget {
    static func parameters(tokenId: String, query: PolymarketPriceHistoryQuery) -> [String: Any] {
        var parameters: [String: Any] = [
            Constants.marketKey: tokenId,
            Constants.fidelityKey: query.fidelityMinutes,
        ]

        switch query.window {
        case .interval(let interval):
            parameters[Constants.intervalKey] = interval.rawValue
        case .range(let start, let end):
            parameters[Constants.startTimestampKey] = Int(start.timeIntervalSince1970)

            if let end {
                parameters[Constants.endTimestampKey] = Int(end.timeIntervalSince1970)
            }
        }

        return parameters
    }

    static func parameters(for asset: PolymarketBalanceAllowanceAsset) -> [String: Any] {
        var parameters: [String: Any] = [
            Constants.assetTypeKey: asset.assetType,
            Constants.signatureTypeKey: Constants.poly1271SignatureType,
        ]

        if let tokenId = asset.tokenId {
            parameters[Constants.tokenIdKey] = tokenId
        }

        return parameters
    }

    enum Constants {
        static let assetTypeKey = "asset_type"
        static let tokenIdKey = "token_id"
        static let sideKey = "side"
        static let marketKey = "market"
        static let intervalKey = "interval"
        static let fidelityKey = "fidelity"
        static let startTimestampKey = "startTs"
        static let endTimestampKey = "endTs"
        static let signatureTypeKey = "signature_type"

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
