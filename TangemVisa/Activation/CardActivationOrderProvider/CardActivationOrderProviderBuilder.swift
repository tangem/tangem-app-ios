//
//  CardActivationOrderProviderBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

struct CardActivationOrderProviderBuilder {
    private let apiType: VisaAPIType

    init(apiType: VisaAPIType) {
        self.apiType = apiType
    }

    func build(
        urlSessionConfiguration: URLSessionConfiguration,
        tokensHandler: VisaAuthorizationTokensHandler,
        cardActivationStatusService: VisaCardActivationStatusService?
    ) -> CardActivationOrderProvider {
        let cardActivationStatusService = cardActivationStatusService ?? VisaCardActivationStatusServiceBuilder(
            apiType: apiType
        ).build(urlSessionConfiguration: urlSessionConfiguration)

        let productActivationService = CommonProductActivationService(
            apiType: apiType,
            apiService: TangemPayAPIService(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: "",
                    authorizationTokensHandler: nil,
                    configuration: urlSessionConfiguration
                ),
                decoder: JSONDecoder(),
                responseFormat: .wrapped
            )
        )

        return CommonCardActivationOrderProvider(
            accessTokenProvider: tokensHandler,
            activationStatusService: cardActivationStatusService,
            productActivationService: productActivationService
        )
    }
}
