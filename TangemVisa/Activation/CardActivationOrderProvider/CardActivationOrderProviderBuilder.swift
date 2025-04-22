//
//  CardActivationOrderProviderBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CardActivationOrderProviderBuilder {
    private let isMockedAPIEnabled: Bool
    private let apiType: VisaAPIType

    init(apiType: VisaAPIType, isMockedAPIEnabled: Bool) {
        self.apiType = apiType
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    func build(
        urlSessionConfiguration: URLSessionConfiguration,
        tokensHandler: VisaAuthorizationTokensHandler,
        cardActivationStatusService: VisaCardActivationStatusService?
    ) -> CardActivationOrderProvider {
        if isMockedAPIEnabled {
            return CardActivationTaskOrderProviderMock()
        }

        let cardActivationStatusService = cardActivationStatusService ?? VisaCardActivationStatusServiceBuilder(
            apiType: apiType, isMockedAPIEnabled: isMockedAPIEnabled).build(urlSessionConfiguration: urlSessionConfiguration)

        let productActivationService = CommonProductActivationService(
            apiType: apiType,
            authorizationTokensHandler: tokensHandler,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                decoder: JSONDecoder()
            )
        )

        return CommonCardActivationOrderProvider(
            accessTokenProvider: tokensHandler,
            activationStatusService: cardActivationStatusService,
            productActivationService: productActivationService
        )
    }
}
