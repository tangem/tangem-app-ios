//
//  ExpressAPIProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExpressAPIProviderFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeExpressAPIProvider(userId: String, logger: Logger) -> ExpressAPIProvider {
        let factory = TangemExpressFactory()
        let isProduction = !AppEnvironment.current.isDebug
        let exchangeDataDecoder = CommonExpressExchangeDataDecoder(
            publicKey: keysManager.expressKeys.signVerifierPublicKey
        )

        let credentials = ExpressAPICredential(
            apiKey: keysManager.expressKeys.apiKey,
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
