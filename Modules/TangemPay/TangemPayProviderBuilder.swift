//
//  TangemPayProviderBuilder.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

public struct TangemPayProviderBuilder {
    public init() {}

    public func buildProvider<T: TargetType>(
        configuration: URLSessionConfiguration,
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler?
    ) -> TangemProvider<T> {
        var plugins: [PluginType] = [
            DeviceInfoPlugin(),
            TangemNetworkLoggerPlugin(logOptions: .verbose),
        ]

        if let authorizationTokensHandler {
            plugins.append(TangemPayAuthorizationPlugin(authorizationTokensHandler: authorizationTokensHandler))
        }

        return TangemProvider<T>(plugins: plugins, sessionConfiguration: configuration)
    }
}

struct TangemPayAuthorizationPlugin: PluginType {
    let authorizationTokensHandler: TangemPayAuthorizationTokensHandler

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        if let authorizationToken = authorizationTokensHandler.authorizationHeader {
            request.headers.add(name: "Authorization", value: authorizationToken)
        }

        return request
    }
}
