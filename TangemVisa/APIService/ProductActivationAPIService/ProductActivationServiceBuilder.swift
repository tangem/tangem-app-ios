//
//  ProductActivationServiceBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ProductActivationServiceBuilder {
    private let isMockedAPIEnabled: Bool
    private let apiType: VisaAPIType

    init(apiType: VisaAPIType, isMockedAPIEnabled: Bool) {
        self.apiType = apiType
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    func build(urlSessionConfiguration: URLSessionConfiguration, authorizationTokensHandler: VisaAuthorizationTokensHandler) -> ProductActivationService {
        if isMockedAPIEnabled {
            return ProductActivationServiceMock()
        }

        return CommonProductActivationService(
            apiType: apiType,
            authorizationTokensHandler: authorizationTokensHandler,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                decoder: JSONDecoder()
            )
        )
    }
}
