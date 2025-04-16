//
//  NFTNetworkPlugin.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Moya
import Foundation

public struct NetworkHeadersPlugin: PluginType {
    let networkHeaders: [APIHeaderKeyInfo]

    public init(networkHeaders: [APIHeaderKeyInfo]) {
        self.networkHeaders = networkHeaders
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        networkHeaders.forEach {
            request.headers.add(name: $0.headerName, value: $0.headerValue)
        }
        return request
    }
}
