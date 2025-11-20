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

struct TangemPayProviderBuilder {
    func buildProvider<T: TargetType>(
        configuration: URLSessionConfiguration,
        authorizationTokensHandler: VisaAuthorizationTokensHandler?
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
    let authorizationTokensHandler: VisaAuthorizationTokensHandler

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        if let authorizationToken = authorizationTokensHandler.authorizationHeader {
            request.headers.add(name: VisaConstants.authorizationHeaderKey, value: authorizationToken)
        }

        return request
    }
}
