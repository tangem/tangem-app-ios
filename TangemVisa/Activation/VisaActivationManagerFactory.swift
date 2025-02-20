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
        urlSessionConfiguration: URLSessionConfiguration
    ) -> VisaActivationManager {
        let internalLogger = InternalLogger()

        let authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder(isMockedAPIEnabled: isMockedAPIEnabled)
            .build(
                cardId: cardId,
                cardActivationStatus: initialActivationStatus,
                refreshTokenSaver: nil,
                urlSessionConfiguration: urlSessionConfiguration
            )

        let authorizationService = VisaAPIServiceBuilder(mockedAPI: isMockedAPIEnabled)
            .buildAuthorizationService(urlSessionConfiguration: urlSessionConfiguration)

        let authorizationProcessor = CommonCardAuthorizationProcessor(
            authorizationService: authorizationService,
            logger: internalLogger
        )

        let cardActivationStatusService = VisaCardActivationStatusServiceBuilder(isMockedAPIEnabled: isMockedAPIEnabled)
            .build(urlSessionConfiguration: urlSessionConfiguration)

        let activationOrderProvider = CardActivationOrderProviderBuilder(isMockedAPIEnabled: isMockedAPIEnabled)
            .build(
                urlSessionConfiguration: urlSessionConfiguration,
                tokensHandler: authorizationTokensHandler,
                cardActivationStatusService: cardActivationStatusService
            )
        let productActivationService = ProductActivationServiceBuilder(isMockAPIEnabled: isMockedAPIEnabled)
            .build(
                urlSessionConfiguration: urlSessionConfiguration,
                authorizationTokensHandler: authorizationTokensHandler
            )
        let key = (try? VisaConfigProvider.shared().getRSAPublicKey()) ?? ""
        let pinCodeProcessor = PaymentologyPINCodeProcessor(rsaPublicKey: key)

        return CommonVisaActivationManager(
            initialActivationStatus: initialActivationStatus,
            authorizationTokensHandler: authorizationTokensHandler,
            tangemSdk: tangemSdk,
            authorizationProcessor: authorizationProcessor,
            cardActivationOrderProvider: activationOrderProvider,
            cardActivationStatusService: cardActivationStatusService,
            productActivationService: productActivationService,
            otpRepository: CommonVisaOTPRepository(),
            pinCodeProcessor: pinCodeProcessor,
            logger: internalLogger
        )
    }
}
