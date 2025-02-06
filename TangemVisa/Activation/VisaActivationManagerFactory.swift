//
//  VisaActivationManagerFactory.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Moya

public struct VisaActivationManagerFactory {
    private let isMockedAPIEnabled: Bool
    public init(isMockedAPIEnabled: Bool = false) {
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    public func make(
        cardId: String,
        initialActivationStatus: VisaCardActivationLocalState,
        tangemSdk: TangemSdk,
        urlSessionConfiguration: URLSessionConfiguration,
        logger: VisaLogger
    ) -> VisaActivationManager {
        let internalLogger = InternalLogger(logger: logger)

        let authorizationService = VisaAPIServiceBuilder(mockedAPI: isMockedAPIEnabled)
            .buildAuthorizationService(
                urlSessionConfiguration: urlSessionConfiguration,
                logger: logger
            )

        let authorizationTokensHolder: AuthorizationTokensHolder
        if case .activationStarted(_, let authorizationTokens, _) = initialActivationStatus {
            authorizationTokensHolder = .init(authorizationTokens: authorizationTokens)
        } else {
            authorizationTokensHolder = .init()
        }

        let authorizationTokenRefreshService = VisaAPIServiceBuilder(mockedAPI: isMockedAPIEnabled)
            .buildAuthorizationTokenRefreshService(
                urlSessionConfiguration: urlSessionConfiguration,
                logger: logger
            )

        let authorizationTokensHandler = CommonVisaAuthorizationTokensHandler(
            cardId: cardId,
            authorizationTokensHolder: authorizationTokensHolder,
            tokenRefreshService: authorizationTokenRefreshService,
            logger: internalLogger,
            refreshTokenSaver: nil
        )

        let authorizationProcessor = CommonCardAuthorizationProcessor(
            authorizationService: authorizationService,
            logger: internalLogger
        )

        let cardActivationStatusService = VisaCardActivationStatusServiceBuilder(isMockedAPIEnabled: isMockedAPIEnabled)
            .build(urlSessionConfiguration: urlSessionConfiguration, logger: logger)

        let activationOrderProvider = CardActivationOrderProviderBuilder(isMockedAPIEnabled: isMockedAPIEnabled)
            .build(
                urlSessionConfiguration: urlSessionConfiguration,
                tokensHandler: authorizationTokensHandler,
                cardActivationStatusService: cardActivationStatusService,
                logger: logger
            )
        let productActivationService = ProductActivationServiceBuilder(isMockAPIEnabled: isMockedAPIEnabled)
            .build(
                urlSessionConfiguration: urlSessionConfiguration,
                authorizationTokensHandler: authorizationTokensHandler,
                logger: logger
            )

        return CommonVisaActivationManager(
            initialActivationStatus: initialActivationStatus,
            authorizationService: authorizationService,
            authorizationTokensHandler: authorizationTokensHandler,
            tangemSdk: tangemSdk,
            authorizationProcessor: authorizationProcessor,
            cardActivationOrderProvider: activationOrderProvider,
            cardActivationStatusService: cardActivationStatusService,
            productActivationService: productActivationService,
            otpRepository: CommonVisaOTPRepository(),
            logger: internalLogger
        )
    }
}
