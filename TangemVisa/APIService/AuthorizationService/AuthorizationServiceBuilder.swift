//
//  AuthorizationServiceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Moya

struct AuthorizationServiceBuilder {
    private let apiType: VisaAPIType

    init(apiType: VisaAPIType) {
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
                decoder: JSONDecoder(),
                responseFormat: .wrapped
            )
        )
    }
}
