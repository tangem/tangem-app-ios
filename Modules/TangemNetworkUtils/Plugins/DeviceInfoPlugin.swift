//
//  DeviceInfoPlugin.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation

public struct DeviceInfoPlugin: PluginType {
    private let deviceInfo: DeviceInfo

    public init(deviceInfo: DeviceInfo = DeviceInfo()) {
        self.deviceInfo = deviceInfo
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request
        let headers = deviceInfo.asHeaders()

        for header in headers {
            request.headers.add(name: header.key, value: header.value)
        }

        return request
    }
}
