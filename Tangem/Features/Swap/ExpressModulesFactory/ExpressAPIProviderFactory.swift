//
//  ExpressAPIProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

struct ExpressAPIProviderFactory {
    // MARK: - Injected

    @Injected(\.keysManager) private var keysManager: KeysManager

    // MARK: - Implementation

    func makeExpressAPIProvider(userWalletId: UserWalletId, refcode: Refcode?) -> ExpressAPIProvider {
        makeExpressAPIProvider(userId: userWalletId.stringValue, refcode: refcode)
    }

    func makeExpressAPIProvider(userId: String, refcode: Refcode?) -> ExpressAPIProvider {
        let factory = TangemExpressFactory()
        let expressAPIType: ExpressAPIType = {
            if AppEnvironment.current.isProduction {
                return .production
            }

            return ExpressAPIType(rawValue: FeatureStorage.instance.apiExpress) ?? .production
        }()

        let apiKey = apiKey(expressAPIType: expressAPIType)
        let publicKey = signVerifierPublicKey(expressAPIType: expressAPIType)
        let exchangeDataDecoder = CommonExpressExchangeDataDecoder(publicKey: publicKey)

        let credentials = ExpressAPICredential(
            apiKey: apiKey,
            userId: userId,
            sessionId: AppConstants.sessionId,
            refcode: refcode?.rawValue
        )

        return factory.makeExpressAPIProvider(
            credential: credentials,
            configuration: .defaultConfiguration,
            expressAPIType: expressAPIType,
            exchangeDataDecoder: exchangeDataDecoder
        )
    }
}

private extension ExpressAPIProviderFactory {
    func apiKey(expressAPIType: ExpressAPIType) -> String {
        switch expressAPIType {
        case .develop, .develop2, .develop3, .stage, .stage2, .mock:
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
        case .develop, .develop2, .develop3, .stage, .stage2, .mock:
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
