//
//  PolymarketOnboardingFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils
import TangemPolymarket

struct PolymarketOnboardingFactory {
    private let services = PolymarketOnboardingServicesFactory(
        networkConfiguration: TangemProviderConfiguration(logOptions: .verbose),
        environment: {
            PolymarketBFFEnvironment(
                baseURL: PolymarketOnboardingFactory.baseURL(),
                headers: PolymarketOnboardingFactory.headers()
            )
        }
    )

    func makeWalletService() -> PolymarketDepositWalletService {
        services.makeWalletService()
    }

    func makeCLOBService() -> PolymarketCLOBService {
        services.makeCLOBService()
    }
}

// MARK: - Private implementation

private extension PolymarketOnboardingFactory {
    static func baseURL() -> URL {
        let apiBaseURL = AppEnvironment.current.apiBaseUrl
        var components = URLComponents(url: apiBaseURL, resolvingAgainstBaseURL: false)
        components?.path = ""
        return components?.url ?? apiBaseURL
    }

    static func headers() -> [String: String] {
        var headers = DeviceInfo().asHeaders()

        if let apiKeyHeader = TangemAPIKeyProvider().getApiKeyHeader() {
            headers[apiKeyHeader.name] = apiKeyHeader.value
        }

        return headers
    }
}
