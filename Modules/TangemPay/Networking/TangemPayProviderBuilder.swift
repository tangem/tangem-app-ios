//
//  TangemPayProviderBuilder.swift
//  TangemVisa
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
        return TangemProvider<T>(
            configuration: TangemProviderConfiguration(
                logOptions: .verbose,
                urlSessionConfiguration: configuration
            ),
            additionalPlugins: [
                DeviceInfoPlugin(),
                TangemPayDefaultHeadersPlugin(),
                TangemPayAuthorizationPlugin(
                    bffStaticToken: bffStaticToken,
                    authorizationTokensHandler: authorizationTokensHandler
                ),
            ]
        )
    }
}

struct TangemPayDefaultHeadersPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        request.headers.add(
            name: TangemPayNetworkingConstants.Header.Key.contentType,
            value: TangemPayNetworkingConstants.Header.Value.applicationJson
        )

        return request
    }
}

struct TangemPayAuthorizationPlugin: PluginType {
    let bffStaticToken: String
    let authorizationTokensHandler: TangemPayAuthorizationTokensHandler?

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        request.headers.add(
            name: TangemPayNetworkingConstants.Header.Key.xApiKey,
            value: bffStaticToken
        )

        if let authorizationToken = authorizationTokensHandler?.authorizationHeader {
            request.headers.add(
                name: TangemPayNetworkingConstants.Header.Key.authorization,
                value: authorizationToken
            )
        }

        return request
    }
}
