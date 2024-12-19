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
    public init() {}

    public func make(
        initialActivationStatus: VisaCardActivationStatus,
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

        let customerInfoManagementService = CommonCustomerInfoManagementService(
            authorizationTokenHandler: tokenHandler,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                logger: internalLogger,
                decoder: JSONDecoderFactory().makeCIMDecoder()
            )
        )
        let authorizationProcessor = CommonCardAuthorizationProcessor(
            authorizationService: authorizationService,
            logger: internalLogger
        )
        let activationOrderProvider = CommonCardActivationOrderProvider(
            accessTokenProvider: tokenHandler,
            customerInfoManagementService: customerInfoManagementService,
            logger: internalLogger
        )

        return CommonVisaActivationManager(
            initialActivationStatus: initialActivationStatus,
            authorizationService: authorizationService,
            authorizationTokenHandler: tokenHandler,
            tangemSdk: tangemSdk,
            authorizationProcessor: authorizationProcessor,
            cardActivationOrderProvider: activationOrderProvider,
            otpRepository: CommonVisaOTPRepository(),
            logger: internalLogger
        )
    }
}
