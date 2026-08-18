//
//  PolymarketOnboardingServicesFactory.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct PolymarketOnboardingServicesFactory {
    private let networkConfiguration: TangemProviderConfiguration

    public init(networkConfiguration: TangemProviderConfiguration) {
        self.networkConfiguration = networkConfiguration
    }

    public func makeWalletService(baseURL: URL, headers: [APIHeaderKeyInfo]) -> PolymarketWalletService {
        let provider = TangemProvider<PolymarketWalletTarget>(
            configuration: networkConfiguration,
            additionalPlugins: [NetworkHeadersPlugin(networkHeaders: headers)]
        )

        return CommonPolymarketWalletService(provider: provider, baseURL: baseURL)
    }
}
