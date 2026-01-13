//
//  AuthorizationServiceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Moya
import TangemPay

struct AuthorizationServiceBuilder {
    private let apiType: TangemPayAPIType

    init(apiType: TangemPayAPIType) {
        self.apiType = apiType
    }

    func build(urlSessionConfiguration: URLSessionConfiguration) -> CommonVisaAuthorizationService {
        CommonVisaAuthorizationService(
            apiType: apiType,
            apiService: .init(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: "",
                    authorizationTokensHandler: nil,
                    configuration: urlSessionConfiguration
                ),
                decoder: JSONDecoderFactory().makePayAPIDecoder()
            )
        )
    }
}
