//
//  TangemProviderConfiguration.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation
import Moya
import TangemFoundation

public struct TangemProviderConfiguration {
    public let logOptions: TangemNetworkLoggerPlugin.LogOptions?
    public let urlSessionConfiguration: URLSessionConfiguration
    public let credentials: Credentials?
    public let headerValues: [APIHeaderKeyInfo]

    public init(
        logOptions: TangemNetworkLoggerPlugin.LogOptions? = .verbose,
        urlSessionConfiguration: URLSessionConfiguration = .defaultConfiguration,
        credentials: Credentials? = nil,
        headerValues: [APIHeaderKeyInfo] = []
    ) {
        self.logOptions = logOptions
        self.urlSessionConfiguration = urlSessionConfiguration
        self.credentials = credentials
        self.headerValues = headerValues
    }

    var plugins: [PluginType] {
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

        plugins.append(NetworkHeadersPlugin(networkHeaders: headerValues))

        if AppEnvironment.current.isUITest {
            plugins.append(WireMockRedirectPlugin())
        }

        return plugins
    }
}

public extension TangemProviderConfiguration {
    struct Credentials: Decodable {
        let user: String
        let password: String

        public init(login: String, password: String) {
            user = login
            self.password = password
        }
    }
}

public extension TangemProviderConfiguration {
    static let ephemeralConfiguration = TangemProviderConfiguration(
        logOptions: .verbose,
        urlSessionConfiguration: .ephemeralConfiguration
    )
}
