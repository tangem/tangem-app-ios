//
//  TangemPayCustomerInfoManagementServiceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNetworkUtils
import TangemPay

public struct TangemPayCustomerInfoManagementServiceBuilder {
    private let apiType: TangemPayAPIType

    public init(apiType: TangemPayAPIType) {
        self.apiType = apiType
    }
}

public extension TangemPayCustomerInfoManagementServiceBuilder {
    func buildCustomerInfoManagementService(
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> CustomerInfoManagementService {
        CommonCustomerInfoManagementService(
            apiType: apiType,
            authorizationTokenHandler: authorizationTokensHandler,
            apiService: .init(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: "",
                    authorizationTokensHandler: nil,
                    configuration: urlSessionConfiguration
                ),
                decoder: JSONDecoderFactory().makeCIMDecoder()
            )
        )
    }
}
