//
//  ExpressAPIProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemBackendAuthentication
import TangemExpress
import TangemFoundation
import class Alamofire.Interceptor

struct ExpressAPIProviderFactory {
    // MARK: - Injected

    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Implementation

    func makeExpressAPIProvider(userWalletId: UserWalletId, refcode: Refcode?) -> ExpressAPIProvider {
        makeExpressAPIProvider(userId: userWalletId.stringValue, refcode: refcode)
    }

    func makeExpressAPIProvider(userId: String, refcode: Refcode?, sendsBatchId: Bool = true) -> ExpressAPIProvider {
        let factory = TangemExpressFactory()
        let expressAPIType = AppEnvironment.current.expressAPIType

        let apiKey = apiKey(expressAPIType: expressAPIType)
        let exchangeDataDecoder = exchangeDataDecoder(expressAPIType: expressAPIType)

        let credentials = ExpressAPICredential(
            apiKey: apiKey,
            userId: userId,
            sessionId: AppConstants.sessionId,
            refcode: refcode?.rawValue,
            batchId: sendsBatchId ? batchId(userId: userId) : nil
        )

        let featureFlags = ExpressFeatureFlags(
            isAPIV2Enabled: true
        )

        return factory.makeExpressAPIProvider(
            credential: credentials,
            configuration: .defaultConfiguration,
            expressAPIType: expressAPIType,
            exchangeDataDecoder: exchangeDataDecoder,
            featureFlags: featureFlags,
            requestInterceptor: authenticationInterceptor
        )
    }
}

private extension ExpressAPIProviderFactory {
    func batchId(userId: String) -> String? {
        userWalletRepository.models
            .first(where: { $0.userWalletId.stringValue == userId })?
            .refcodeProvider?
            .batchId
    }

    var authenticationInterceptor: Interceptor {
        Interceptor(
            adapter: BackendAuthenticationAssembly.requestAdapter,
            retrier: BackendAuthenticationAssembly.requestRetrier
        )
    }

    func apiKey(expressAPIType: ExpressAPIType) -> String {
        switch expressAPIType {
        case .develop, .developNew, .develop2, .develop2New, .develop3, .develop3New,
             .stage, .develop4New, .stage2, .develop5New, .stage3, .develop6New, .mock:
            if let apiKey = keysManager.devExpressKeys?.apiKey {
                return apiKey
            }

            assertionFailure("[Express] ApiKey not found")
            return ""
        case .production, .productionNew:
            return keysManager.expressKeys.apiKey
        }
    }

    func exchangeDataDecoder(expressAPIType: ExpressAPIType) -> ExpressExchangeDataDecoder {
        #if DEBUG
        if expressAPIType == .mock {
            return MockExpressExchangeDataDecoder()
        }
        #endif
        let publicKey = signVerifierPublicKey(expressAPIType: expressAPIType)
        return CommonExpressExchangeDataDecoder(publicKey: publicKey)
    }

    func signVerifierPublicKey(expressAPIType: ExpressAPIType) -> String {
        switch expressAPIType {
        case .develop, .developNew, .develop2, .develop2New, .develop3, .develop3New,
             .stage, .develop4New, .stage2, .develop5New, .stage3, .develop6New, .mock:
            if let publicKey = keysManager.devExpressKeys?.signVerifierPublicKey {
                return publicKey
            }

            assertionFailure("[Express] SignVerifierPublicKey not found")
            return ""
        case .production, .productionNew:
            return keysManager.expressKeys.signVerifierPublicKey
        }
    }
}
