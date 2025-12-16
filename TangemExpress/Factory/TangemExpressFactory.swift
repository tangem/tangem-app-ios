//
//  TangemExpressFactory.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemSdk
import TangemNetworkUtils

public struct TangemExpressFactory {
    public init() {}

    // MARK: - Swap

    public func makeExpressManager(
        expressAPIProvider: ExpressAPIProvider,
        expressRepository: ExpressRepository,
        supportedProviderTypes: [ExpressProviderType],
        operationType: ExpressOperationType,
        transactionValidator: ExpressProviderTransactionValidator
    ) -> ExpressManager {
        let factory = CommonExpressProviderManagerFactory(
            expressAPIProvider: expressAPIProvider,
            mapper: .init(),
            transactionValidator: transactionValidator
        )

        return CommonExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressProviderManagerFactory: factory,
            expressRepository: expressRepository,
            supportedProviderTypes: supportedProviderTypes,
            operationType: operationType
        )
    }

    // MARK: - Onramp

    public func makeOnrampManager(
        expressAPIProvider: ExpressAPIProvider,
        onrampRepository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        analyticsLogger: ExpressAnalyticsLogger,
        providerItemSorter: ProviderItemSorter,
        preferredValues: PreferredValues,
    ) -> OnrampManager {
        CommonOnrampManager(
            apiProvider: expressAPIProvider,
            onrampRepository: onrampRepository,
            dataRepository: dataRepository,
            analyticsLogger: analyticsLogger,
            sorter: providerItemSorter,
            preferredValues: preferredValues
        )
    }

    public func makeOnrampRepository(storage: OnrampStorage) -> OnrampRepository {
        let repository = CommonOnrampRepository(storage: storage)
        return repository
    }

    public func makeOnrampDataRepository(expressAPIProvider: ExpressAPIProvider) -> OnrampDataRepository {
        let repository = CommonOnrampDataRepository(provider: expressAPIProvider)
        return repository
    }

    // MARK: - API

    public func makeExpressAPIProvider(
        credential: ExpressAPICredential,
        configuration: URLSessionConfiguration,
        expressAPIType: ExpressAPIType,
        exchangeDataDecoder: ExpressExchangeDataDecoder
    ) -> ExpressAPIProvider {
        let plugins: [PluginType] = [
            ExpressAuthorizationPlugin(
                apiKey: credential.apiKey,
                userId: credential.userId,
                sessionId: credential.sessionId,
                refcode: credential.refcode
            ),
            DeviceInfoPlugin(),
            TangemNetworkLoggerPlugin(logOptions: .verbose),
        ]
        let provider = TangemProvider<ExpressAPITarget>(plugins: plugins, sessionConfiguration: configuration)
        let service = CommonExpressAPIService(provider: provider, expressAPIType: expressAPIType)
        let mapper = ExpressAPIMapper(exchangeDataDecoder: exchangeDataDecoder)
        return CommonExpressAPIProvider(expressAPIService: service, expressAPIMapper: mapper)
    }
}

// MARK: - Injected configurations and dependencies

public struct ExpressAPICredential {
    public let apiKey: String
    public let userId: String
    public let sessionId: String
    public let refcode: String?

    public init(apiKey: String, userId: String, sessionId: String, refcode: String?) {
        self.apiKey = apiKey
        self.userId = userId
        self.sessionId = sessionId
        self.refcode = refcode
    }
}

public enum ExpressAPIType: String, Hashable, CaseIterable {
    case develop
    case develop2
    case develop3
    case production
    case stage
    case mock

    public var title: String {
        switch self {
        case .develop:
            return "dev"
        case .develop2:
            return "dev2"
        case .develop3:
            return "dev3"
        case .production:
            return "prod"
        case .stage:
            return "stage"
        case .mock:
            return "mock"
        }
    }
}
