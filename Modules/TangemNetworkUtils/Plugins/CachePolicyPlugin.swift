//
//  CachePolicyPlugin.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public protocol CachePolicyProvider {
    var cachePolicy: URLRequest.CachePolicy { get }
}

public struct CachePolicyPlugin: PluginType {
    public init() {}

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let cachePolicyProvider = target as? CachePolicyProvider {
            var mutableRequest = request
            mutableRequest.cachePolicy = cachePolicyProvider.cachePolicy
            return mutableRequest
        }

        return request
    }
}
