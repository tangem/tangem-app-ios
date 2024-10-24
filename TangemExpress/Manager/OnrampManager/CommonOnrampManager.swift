//
//  CommonOnrampManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public actor CommonOnrampManager {
    private let apiProvider: ExpressAPIProvider
    private let onrampRepository: OnrampRepository
    private let dataRepository: OnrampDataRepository
    private let logger: Logger

    private var _providers: [Provider] = []

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
    public func getCountry() async throws -> OnrampCountry {
        if let country = onrampRepository.savedCountry {
            return country
        }

        try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
        let country: OnrampCountry = .random() ? .rus : .usa

        onrampRepository.updatePreference(country: country)
        return country
    }

    public func loadProviders(request: OnrampPairRequestItem) async throws {
        let pairs = try await apiProvider.onrampPairs(
            from: request.fiatCurrency,
            to: [request.destination.expressCurrency],
            country: request.country
        )

        _providers = pairs.flatMap { $0.providers }.map { provider in
            makeProvider(item: request, provider: provider)
        }
    }

    public func loadQuotes(amount: Decimal) async throws {
        await withTaskGroup(of: Void.self) { [weak self] group in
            await self?._providers.forEach { provider in
                _ = group.addTaskUnlessCancelled {
                    await provider.manager.update(amount: amount)
                }
            }
        }
    }

    public func loadOnrampData(request: OnrampQuotesRequestItem) async throws -> OnrampRedirectData {
        // Load data from API
        throw OnrampManagerError.notImplement
    }
}

// MARK: - Private

private extension CommonOnrampManager {
    func makeProvider(item: OnrampPairRequestItem, provider: OnrampProvider) -> Provider {
        Provider(
            manager: CommonOnrampProviderManager(
                item: item,
                provider: provider,
                dataRepository: dataRepository,
                apiProvider: apiProvider
            )
        )
    }
}

// TEMP MOCK

extension OnrampCountry {
    static let usa = OnrampCountry(identity: .usa, currency: .init(identity: .usd, precision: 2), onrampAvailable: true)
    static let rus = OnrampCountry(identity: .rus, currency: .init(identity: .rub, precision: 2), onrampAvailable: false)
}

extension OnrampIdentity {
    static let usa = OnrampIdentity(
        name: "USA",
        code: "US",
        image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/currencies/medium/usd.png")!
    )

    static let usd = OnrampIdentity(
        name: "US Dollar",
        code: "USD",
        image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/currencies/medium/usd.png")!
    )

    static let rus = OnrampIdentity(
        name: "Russia",
        code: "RU",
        image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/currencies/medium/rub.png")!
    )

    static let rub = OnrampIdentity(
        name: "Ruble",
        code: "RUB",
        image: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/currencies/medium/rub.png")!
    )
}

extension CommonOnrampManager {
    struct Provider {
        let manager: OnrampProviderManager
    }
}
