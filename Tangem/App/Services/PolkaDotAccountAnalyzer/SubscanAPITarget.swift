//
//  SubscanAPITarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct SubscanAPITarget {
    let isTestnet: Bool
    let target: Target
}

// MARK: - Auxiliary types

extension SubscanAPITarget {
    enum Target {
        case getAccountInfo(address: String)
        case getExtrinsicsList(address: String, page: Int, limit: Int)
        case getExtrinsicInfo(hash: String)
    }
}

// MARK: - TargetType protocol conformance

extension SubscanAPITarget: TargetType {
    var baseURL: URL {
        let domain = isTestnet ? "westend" : "polkadot"

        return URL(string: "https://\(domain).api.subscan.io")!
    }

    var path: String {
        let commonPath = "api/scan"
        switch target {
        case .getAccountInfo:
            return commonPath + "/search"
        case .getExtrinsicsList:
            return commonPath + "/extrinsics"
        case .getExtrinsicInfo:
            return commonPath + "/extrinsic"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getAccountInfo,
             .getExtrinsicsList,
             .getExtrinsicInfo:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .getAccountInfo(let address):
            let body = SubscanAPIParams.AccountInfo(key: address)
            return .requestJSONEncodable(body)
        case .getExtrinsicsList(let address, let page, let limit):
            let body = SubscanAPIParams.ExtrinsicsList(address: address, order: .desc, page: page, row: limit)
            return .requestJSONEncodable(body)
        case .getExtrinsicInfo(let hash):
            let body = SubscanAPIParams.ExtrinsicInfo(hash: hash)
            return .requestJSONEncodable(body)
        }
    }

    var headers: [String: String]? {
        return nil
    }
}
