//
//  BlockaidTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct BlockaidTarget: Moya.TargetType {
    let apiKey: String
    let target: Target

    enum Target {
        case scanSite(request: BlockaidDTO.SiteScan.Request)
        case scanEvm(request: BlockaidDTO.EvmScan.Request)
        case scanSolana(request: BlockaidDTO.SolanaScan.Request)
    }

    var baseURL: URL {
        URL(string: "https://api.blockaid.io/v0/")!
    }

    var path: String {
        switch target {
        case .scanSite: "site/scan"
        case .scanEvm: "evm/json-rpc/scan"
        case .scanSolana: "/solana/message/scan"
        }
    }

    var method: Moya.Method {
        switch target {
        case .scanSite, .scanEvm, .scanSolana: .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .scanSite(let request): .requestJSONEncodable(request)
        case .scanEvm(let request): .requestJSONEncodable(request)
        case .scanSolana(let request): .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        ["X-API-Key": apiKey]
    }
}

extension BlockaidTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        true
    }
}
