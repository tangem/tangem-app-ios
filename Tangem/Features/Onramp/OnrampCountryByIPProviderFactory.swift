//
//  OnrampCountryByIPProviderFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

enum OnrampCountryByIPProviderFactory {
    typealias Provider = () async throws -> OnrampCountry

    static func make(userWalletInfo: UserWalletInfo) -> Provider? {
        guard FeatureProvider.isAvailable(.onrampCountryByIP) else {
            return nil
        }

        let expressAPIProvider = CommonExpressDependenciesFactory(
            userWalletInfo: userWalletInfo,
            preferredProviderId: nil,
            mcpIntentID: nil
        ).expressAPIProvider

        return make(expressAPIProvider: expressAPIProvider)
    }

    static func make(expressAPIProvider: ExpressAPIProvider) -> Provider {
        let service = InjectedValues[\.onrampCountryByIPService]

        return { try await service.country(fetch: expressAPIProvider.onrampCountryByIP) }
    }
}
