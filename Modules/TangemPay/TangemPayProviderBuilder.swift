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
        bffStaticToken: String,
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler?,
        configuration: URLSessionConfiguration
    ) -> TangemProvider<T> {
        var plugins: [PluginType] = [
            DeviceInfoPlugin(),
            TangemNetworkLoggerPlugin(logOptions: .verbose),
        ]

        if let authorizationTokensHandler {
            plugins.append(
                TangemPayAuthorizationPlugin(
                    bffStaticToken: bffStaticToken,
                    authorizationTokensHandler: authorizationTokensHandler
                )
            )
        }

        return TangemProvider<T>(plugins: plugins, sessionConfiguration: configuration)
    }
}

struct TangemPayAuthorizationPlugin: PluginType {
    let bffStaticToken: String
    let authorizationTokensHandler: TangemPayAuthorizationTokensHandler

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        request.headers.add(name: "Content-Type", value: "application/json")
        request.headers.add(name: "X-API-KEY", value: bffStaticToken)

        if let authorizationToken = authorizationTokensHandler.authorizationHeader {
            request.headers.add(name: "Authorization", value: authorizationToken)
        }

        return request
    }
}
