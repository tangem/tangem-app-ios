//
//  TangemProvider.swift
//  TangemNetworkUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public class TangemProvider<Target: TargetType>: MoyaProvider<Target> {
    @available(iOS, deprecated: 100000.0, message: "Using this constructor is discouraged, use init(configuration:additionalPlugins:) instead.")
    public init(
        stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
        plugins: [PluginType] = [],
        sessionConfiguration: URLSessionConfiguration = .defaultConfiguration
    ) {
        let serverTrustManager = TangemTrustEvaluatorServerTrustManager()
        let session = Session(configuration: sessionConfiguration, serverTrustManager: serverTrustManager)

        super.init(stubClosure: stubClosure, session: session, plugins: plugins)
    }
}

// MARK: - Convenience initializer

public extension TangemProvider {
    convenience init(
        configuration: TangemProviderConfiguration,
        additionalPlugins: [PluginType] = []
    ) {
        self.init(
            plugins: configuration.plugins + additionalPlugins,
            sessionConfiguration: configuration.urlSessionConfiguration
        )
    }
}
