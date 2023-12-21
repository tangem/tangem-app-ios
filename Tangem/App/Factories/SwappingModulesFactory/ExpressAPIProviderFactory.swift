//
//  ExpressAPIProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping

struct ExpressAPIProviderFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeExpressAPIProvider(userId: String, logger: SwappingLogger) -> ExpressAPIProvider {
        let factory = TangemSwappingFactory(oneInchApiKey: keysManager.oneInchApiKey)
        let isProduction = !AppEnvironment.current.isDebug
        let exchangeDataDecoder = CommonExpressExchangeDataDecoder(
            publicKey: "MFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAE26f5gIs4d+tptv3z3baw4eU4tE5/fwklq3a3QdU0mxM4wR/xCU/w3hmDAIg4ShEZRUe+SBmWYBG9vrut2vaTMA=="
        )

        let credentials = ExpressAPICredential(
            apiKey: keysManager.tangemExpressApiKey,
            userId: userId,
            sessionId: AppConstants.sessionId
        )

        return factory.makeExpressAPIProvider(
            credential: credentials,
            configuration: .defaultConfiguration,
            isProduction: isProduction,
            exchangeDataDecoder: exchangeDataDecoder,
            logger: AppLog.shared
        )
    }
}
