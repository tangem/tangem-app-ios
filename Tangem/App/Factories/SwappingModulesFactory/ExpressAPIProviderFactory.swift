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

        let credentials = ExpressAPICredential(
            apiKey: keysManager.tangemExpressApiKey,
            userId: userId,
            sessionId: AppConstants.sessionId
        )

        return factory.makeExpressAPIProvider(
            credential: credentials,
            configuration: .defaultConfiguration,
            isProduction: isProduction,
            logger: AppLog.shared
        )
    }
}
