//
//  TimeoutIntervalPlugin.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public protocol TimeoutIntervalProvider {
    var timeoutInterval: TimeInterval? { get }
}

public struct TimeoutIntervalPlugin: PluginType {
    public init() {}

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let timeoutIntervalProvider = target as? TimeoutIntervalProvider,
           let timeoutInterval = timeoutIntervalProvider.timeoutInterval {
            var mutableRequest = request
            mutableRequest.timeoutInterval = timeoutInterval
            return mutableRequest
        }

        return request
    }
}
