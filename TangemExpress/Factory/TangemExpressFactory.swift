//
//  TangemExpressFactory.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct TangemExpressFactory {
    public init() {}

    public func makeExpressManager(
        expressAPIProvider: ExpressAPIProvider,
        allowanceProvider: AllowanceProvider,
        feeProvider: FeeProvider,
        expressRepository: ExpressRepository,
        logger: Logger? = nil
    ) -> ExpressManager {
        let logger: Logger = logger ?? CommonLogger()
        let factory = CommonExpressProviderManagerFactory(
            expressAPIProvider: expressAPIProvider,
            allowanceProvider: allowanceProvider,
            feeProvider: feeProvider,
            logger: logger,
            mapper: .init()
        )

        return CommonExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressProviderManagerFactory: factory,
            expressRepository: expressRepository,
            logger: logger
        )
    }

    public func makeExpressAPIProvider(
        credential: ExpressAPICredential,
        configuration: URLSessionConfiguration,
        isProduction: Bool,
        exchangeDataDecoder: ExpressExchangeDataDecoder,
        logger: Logger? = nil
    ) -> ExpressAPIProvider {
        let authorizationPlugin = ExpressAuthorizationPlugin(
            apiKey: credential.apiKey,
            userId: credential.userId,
            sessionId: credential.sessionId
        )
        let provider = MoyaProvider<ExpressAPITarget>(session: Session(configuration: configuration), plugins: [authorizationPlugin])
        let service = CommonExpressAPIService(provider: provider, isProduction: isProduction, logger: logger ?? CommonLogger())
        let mapper = ExpressAPIMapper(exchangeDataDecoder: exchangeDataDecoder)
        return CommonExpressAPIProvider(expressAPIService: service, expressAPIMapper: mapper)
    }
}

// MARK: - Credential

public struct ExpressAPICredential {
    public let apiKey: String
    public let userId: String
    public let sessionId: String

    public init(apiKey: String, userId: String, sessionId: String) {
        self.apiKey = apiKey
        self.userId = userId
        self.sessionId = sessionId
    }
}
