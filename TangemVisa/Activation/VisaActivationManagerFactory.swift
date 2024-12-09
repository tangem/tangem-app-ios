//
//  VisaActivationManagerFactory.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct VisaActivationManagerFactory {
    public init() {}

    public func make(
        cardInput: VisaCardActivationInput,
        tangemSdk: TangemSdk,
        urlSessionConfiguration: URLSessionConfiguration,
        logger: VisaLogger
    ) -> VisaActivationManager {
        let internalLogger = InternalLogger(logger: logger)
        let authorizationService = AuthorizationServiceBuilder().build(urlSessionConfiguration: urlSessionConfiguration, logger: logger)
        let tokenHandler = CommonVisaAccessTokenHandler(
            tokenRefreshService: authorizationService,
            logger: internalLogger,
            refreshTokenSaver: nil
        )

        let customerInfoService = CommonCustomerInfoService(authorizationTokenHandler: tokenHandler)
        let authorizationProcessor = CommonCardAuthorizationProcessor(
            authorizationService: authorizationService,
            logger: internalLogger
        )

        let activationOrderProvider = CommonCardActivationOrderProvider(
            accessTokenProvider: tokenHandler,
            customerInfoService: customerInfoService,
            logger: internalLogger
        )

        return CommonVisaActivationManager(
            cardInput: cardInput,
            authorizationService: authorizationService,
            authorizationTokenHandler: tokenHandler,
            tangemSdk: tangemSdk,
            authorizationProcessor: authorizationProcessor,
            cardActivationOrderProvider: activationOrderProvider,
            logger: internalLogger
        )
    }
}
