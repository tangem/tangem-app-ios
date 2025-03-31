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
        case scan(request: BlockaidDTO.Scan.Request)
    }
    
    var baseURL: URL {
        URL(string: "https://api.blockaid.io/v0/")!
    }
    
    var path: String {
        switch target {
        case .scan(let url):
            return "site/scan"
        }
    }

    var method: Moya.Method {
        switch target {
        case .scan: .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .scan(let request): .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        ["X-API-KEY": apiKey]
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

