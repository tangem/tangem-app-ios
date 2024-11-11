//
//  CommonOnrampManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public actor CommonOnrampManager {
    private let apiProvider: ExpressAPIProvider
    private let onrampRepository: OnrampRepository
    private let dataRepository: OnrampDataRepository
    private let logger: Logger

    private var _providers: [OnrampProvider] = []

    public init(
        apiProvider: ExpressAPIProvider,
        onrampRepository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        logger: Logger
    ) {
        self.apiProvider = apiProvider
        self.onrampRepository = onrampRepository
        self.dataRepository = dataRepository
        self.logger = logger
    }
}

// MARK: - OnrampManager

extension CommonOnrampManager: OnrampManager {
    public func initialSetupCountry() async throws -> OnrampCountry {
        let country = try await apiProvider.onrampCountryByIP()
        return country
    }

    public func setupProviders(request: OnrampPairRequestItem) async throws -> [OnrampProvider] {
        let pairs = try await apiProvider.onrampPairs(
            from: request.fiatCurrency,
            to: [request.destination.expressCurrency],
            country: request.country
        )

        // [REDACTED_TODO_COMMENT]

        return _providers
    }

    public func setupQuotes(amount: Decimal) async throws -> [OnrampProvider] {
        /*
         TODO: https://tangem.atlassian.net/browse/[REDACTED_INFO]
         await withTaskGroup(of: Void.self) { [weak self] group in
             await self?._providers.forEach { provider in
                 _ = group.addTaskUnlessCancelled {
                     await provider.manager.update(amount: amount)
                 }
             }
         }
         */

        return _providers
    }

    public func loadOnrampData(request: OnrampQuotesRequestItem) async throws -> OnrampRedirectData {
        // Load data from API
        throw OnrampManagerError.notImplement
    }
}

// MARK: - Private

private extension CommonOnrampManager {
    func makeProvider(item: OnrampPairRequestItem, provider: OnrampPair.Provider) -> OnrampProvider {
        // Construct a OnrampProvider wrapper with autoupdating itself
        // [REDACTED_TODO_COMMENT]
        OnrampProvider(provider: provider)
    }
}
