//
//  NetworkProviderConfiguration.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation
import Moya

public struct NetworkProviderConfiguration {
    public let logOptions: TangemNetworkLoggerPlugin.LogOptions?
    public let urlSessionConfiguration: URLSessionConfiguration
    public let credentials: Credentials?

    public init(
        logOptions: TangemNetworkLoggerPlugin.LogOptions? = .default,
        urlSessionConfiguration: URLSessionConfiguration = .defaultConfiguration,
        credentials: Credentials? = nil
    ) {
        self.logOptions = logOptions
        self.urlSessionConfiguration = urlSessionConfiguration
        self.credentials = credentials
    }

    public var plugins: [PluginType] {
        var plugins: [PluginType] = []

        if let logOptions = logOptions {
            plugins.append(TangemNetworkLoggerPlugin(logOptions: logOptions))
        }

        if let credentials {
            plugins.append(CredentialsPlugin { _ -> URLCredential? in
                .init(
                    user: credentials.user,
                    password: credentials.password,
                    persistence: .none
                )
            })
        }

        return plugins
    }
}

public extension NetworkProviderConfiguration {
    struct Credentials: Decodable {
        let user: String
        let password: String

        public init(login: String, password: String) {
            user = login
            self.password = password
        }
    }
}
