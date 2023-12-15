//
//  TangemSwappingFactory.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct TangemSwappingFactory {
    private let oneInchApiKey: String

    public init(oneInchApiKey: String) {
        self.oneInchApiKey = oneInchApiKey
    }

    public func makeSwappingManager(
        walletDataProvider: SwappingWalletDataProvider,
        referrer: SwappingReferrerAccount? = nil,
        source: Currency,
        destination: Currency?,
        amount: Decimal? = nil,
        logger: SwappingLogger? = nil
    ) -> SwappingManager {
        let swappingItems = SwappingItems(source: source, destination: destination)
        let swappingService = OneInchAPIService(logger: logger ?? CommonSwappingLogger(), oneInchApiKey: oneInchApiKey)
        let provider = OneInchSwappingProvider(swappingService: swappingService)

        return CommonSwappingManager(
            swappingProvider: provider,
            walletDataProvider: walletDataProvider,
            logger: logger ?? CommonSwappingLogger(),
            referrer: referrer,
            swappingItems: swappingItems,
            amount: amount
        )
    }

    public func makeExpressManager(
        expressAPIProvider: ExpressAPIProvider,
        allowanceProvider: AllowanceProvider,
        feeProvider: FeeProvider,
        expressRepository: ExpressRepository,
        logger: SwappingLogger? = nil
    ) -> ExpressManager {
        let logger: SwappingLogger = logger ?? CommonSwappingLogger()
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
        logger: SwappingLogger? = nil
    ) -> ExpressAPIProvider {
        let authorizationPlugin = ExpressAuthorizationPlugin(
            apiKey: credential.apiKey,
            userId: credential.userId,
            sessionId: credential.sessionId
        )
        let provider = MoyaProvider<ExpressAPITarget>(session: Session(configuration: configuration), plugins: [authorizationPlugin])
        let service = CommonExpressAPIService(provider: provider, isProduction: isProduction, logger: logger ?? CommonSwappingLogger())
        let mapper = ExpressAPIMapper()
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
