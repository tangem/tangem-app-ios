//
//  MoralisTokenBalanceAPITarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Moya

struct MoralisTokenBalanceAPITarget: TargetType {
    let target: Target

    enum Target: Equatable {
        case tokenBalances(address: String, chain: String)
    }

    var baseURL: URL {
        URL(string: "https://deep-index.moralis.io/api/v2.2")!
    }

    var path: String {
        switch target {
        case .tokenBalances(let address, _):
            return "/wallets/\(address)/tokens"
        }
    }

    var method: Moya.Method {
        switch target {
        case .tokenBalances:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .tokenBalances(_, let chain):
            return .requestParameters(
                parameters: ["chain": chain],
                encoding: URLEncoding(destination: .queryString)
            )
        }
    }

    var headers: [String: String]? {
        nil
    }
}
