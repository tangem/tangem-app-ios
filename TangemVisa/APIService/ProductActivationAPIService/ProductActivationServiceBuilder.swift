//
//  ProductActivationServiceBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

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
            apiService: .init(
                provider: TangemProvider(plugins: [], sessionConfiguration: urlSessionConfiguration),
                decoder: JSONDecoder()
            )
        )
    }
}
