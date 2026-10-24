//
//  TangemExpressFactory.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct TangemExpressFactory {
    public init() {}

    // MARK: - Swap

    public func makeExpressManager(
        expressAPIProvider: ExpressAPIProvider,
        expressRepository: ExpressRepository,
        featureFlags: ExpressFeatureFlags,
        preferredProviderId: ExpressProvider.Id? = nil
    ) -> ExpressManager {
        let factory = CommonExpressProviderManagerFactory(
            expressAPIProvider: expressAPIProvider,
            mapper: .init(),
            featureFlags: featureFlags
        )

        return CommonExpressManager(
            expressAPIProvider: expressAPIProvider,
            expressProviderManagerFactory: factory,
            expressRepository: expressRepository,
            featureFlags: featureFlags,
            preferredProviderId: preferredProviderId
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
        exchangeDataDecoder: ExpressExchangeDataDecoder,
        featureFlags: ExpressFeatureFlags
    ) -> ExpressAPIProvider {
        let provider = TangemProvider<ExpressAPITarget>(
            configuration: TangemProviderConfiguration(
                logOptions: .verbose,
                urlSessionConfiguration: configuration
            ),
            additionalPlugins: [
                ExpressAuthorizationPlugin(
                    apiKey: credential.apiKey,
                    userId: credential.userId,
                    sessionId: credential.sessionId,
                    refcode: credential.refcode
                ),
                DeviceInfoPlugin(),
            ]
        )
        let service = CommonExpressAPIService(provider: provider, expressAPIType: expressAPIType)
        let mapper = ExpressAPIMapper(exchangeDataDecoder: exchangeDataDecoder, featureFlags: featureFlags)
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
    case developNew
    case develop2
    case develop2New
    case develop3
    case develop3New
    case production
    case productionNew
    case stage
    case develop4New
    case stage2
    case develop5New
    case stage3
    case develop6New
    case mock

    public var title: String {
        switch self {
        case .develop:
            return "dev"
        case .developNew:
            return "dev (new)"
        case .develop2:
            return "dev2"
        case .develop2New:
            return "dev2 (new)"
        case .develop3:
            return "dev3"
        case .develop3New:
            return "dev3 (new)"
        case .production:
            return "prod"
        case .productionNew:
            return "prod (new)"
        case .stage:
            return "stage"
        case .develop4New:
            return "dev4 (new)"
        case .stage2:
            return "stage2"
        case .develop5New:
            return "dev5 (new)"
        case .stage3:
            return "stage3"
        case .develop6New:
            return "dev6 (new)"
        case .mock:
            return "mock"
        }
    }
}
