//
//  ProductActivationServiceBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ProductActivationServiceBuilder {
    private let apiType: VisaAPIType

    init(apiType: VisaAPIType) {
        self.apiType = apiType
    }

    func build(urlSessionConfiguration: URLSessionConfiguration, authorizationTokensHandler: VisaAuthorizationTokensHandler) -> ProductActivationService {
        CommonProductActivationService(
            apiType: apiType,
            apiService: .init(
                provider: TangemPayProviderBuilder().buildProvider(
                    configuration: urlSessionConfiguration,
                    authorizationTokensHandler: nil
                ),
                decoder: JSONDecoder()
            )
        )
    }
}
