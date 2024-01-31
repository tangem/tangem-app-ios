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
        let expressAPIType: ExpressAPIType = {
            if AppEnvironment.current.isProduction {
                return .production
            }

            return FeatureStorage().useDevApi ? .develop : .production
        }()

        let apiKey = apiKey(expressAPIType: expressAPIType)
        let publicKey = signVerifierPublicKey(expressAPIType: expressAPIType)
        let exchangeDataDecoder = CommonExpressExchangeDataDecoder(publicKey: publicKey)

        let credentials = ExpressAPICredential(
            apiKey: apiKey,
            userId: userId,
            sessionId: AppConstants.sessionId
        )

        return factory.makeExpressAPIProvider(
            credential: credentials,
            configuration: .defaultConfiguration,
            expressAPIType: expressAPIType,
            exchangeDataDecoder: exchangeDataDecoder,
            logger: AppLog.shared
        )
    }
}

private extension ExpressAPIProviderFactory {
    func apiKey(expressAPIType: ExpressAPIType) -> String {
        switch expressAPIType {
        case .develop:
            if let apiKey = keysManager.devExpressKeys?.apiKey {
                return apiKey
            }

            assertionFailure("[Express] ApiKey not found")
            return ""
        case .production:
            return keysManager.expressKeys.apiKey
        }
    }

    func signVerifierPublicKey(expressAPIType: ExpressAPIType) -> String {
        switch expressAPIType {
        case .develop:
            if let publicKey = keysManager.devExpressKeys?.signVerifierPublicKey {
                return publicKey
            }

            assertionFailure("[Express] SignVerifierPublicKey not found")
            return ""
        case .production:
            return keysManager.expressKeys.signVerifierPublicKey
        }
    }
}
