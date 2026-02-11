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
import TangemPay

public struct VisaActivationManagerFactory {
    private let apiType: VisaAPIType
    private let isTestnet: Bool

    public init(apiType: VisaAPIType, isTestnet: Bool) {
        self.apiType = apiType
        self.isTestnet = isTestnet
    }

    public func make(
        cardId: String,
        initialActivationStatus: VisaCardActivationLocalState,
        tangemSdk: TangemSdk,
        urlSessionConfiguration: URLSessionConfiguration
    ) -> VisaActivationManager {
        let authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder(apiType: apiType)
            .build(
                cardId: cardId,
                cardActivationStatus: initialActivationStatus,
                refreshTokenSaver: nil,
                allowRefresherTask: true,
                urlSessionConfiguration: urlSessionConfiguration
            )

        let authorizationService = VisaAPIServiceBuilder(apiType: apiType)
            .buildAuthorizationService(urlSessionConfiguration: urlSessionConfiguration)

        let authorizationProcessor = CommonCardAuthorizationProcessor(authorizationService: authorizationService)

        let cardActivationStatusService = VisaCardActivationStatusServiceBuilder(apiType: apiType)
            .build(urlSessionConfiguration: urlSessionConfiguration)

        let activationOrderProvider = CardActivationOrderProviderBuilder(apiType: apiType)
            .build(
                urlSessionConfiguration: urlSessionConfiguration,
                tokensHandler: authorizationTokensHandler,
                cardActivationStatusService: cardActivationStatusService
            )
        let productActivationService = ProductActivationServiceBuilder(apiType: apiType)
            .build(
                urlSessionConfiguration: urlSessionConfiguration,
                authorizationTokensHandler: authorizationTokensHandler
            )
        let key = (try? VisaConfigProvider.shared().getRSAPublicKey(apiType: apiType)) ?? ""
        let pinCodeProcessor = PaymentologyPINCodeProcessor(rsaPublicKey: key)

        return CommonVisaActivationManager(
            isTestnet: isTestnet,
            initialActivationStatus: initialActivationStatus,
            authorizationTokensHandler: authorizationTokensHandler,
            tangemSdk: tangemSdk,
            authorizationProcessor: authorizationProcessor,
            cardActivationOrderProvider: activationOrderProvider,
            cardActivationStatusService: cardActivationStatusService,
            productActivationService: productActivationService,
            otpRepository: CommonVisaOTPRepository(),
            pinCodeProcessor: pinCodeProcessor
        )
    }
}
