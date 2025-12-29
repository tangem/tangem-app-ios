//
//  TangemPayAPIServiceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNetworkUtils

public struct TangemPayAPIServiceBuilder {
    private let apiType: VisaAPIType
    private let bffStaticToken: String

    public init(apiType: VisaAPIType, bffStaticToken: String) {
        self.apiType = apiType
        self.bffStaticToken = bffStaticToken
    }
}

public extension TangemPayAPIServiceBuilder {
    func buildTangemPayAvailabilityService(
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> TangemPayAvailabilityService {
        CommonTangemPayAvailabilityService(
            apiType: apiType,
            apiService: TangemPayAPIService(
                provider: TangemPayProviderBuilder().buildProvider(
                    configuration: urlSessionConfiguration,
                    authorizationTokensHandler: nil
                ),
                decoder: JSONDecoderFactory().makePayAPIDecoder()
            ),
            bffStaticToken: bffStaticToken
        )
    }

    func buildTangemPayAuthorizationService(
        customerWalletId: String,
        authorizationTokensRepository: TangemPayAuthorizationTokensRepository,
        tokens: TangemPayAuthorizationTokens?,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> TangemPayAuthorizationService {
        CommonTangemPayAuthorizationService(
            customerWalletId: customerWalletId,
            authorizationTokensRepository: authorizationTokensRepository,
            apiType: apiType,
            apiService: TangemPayAPIService(
                provider: TangemPayProviderBuilder().buildProvider(
                    configuration: urlSessionConfiguration,
                    authorizationTokensHandler: nil
                ),
                decoder: JSONDecoderFactory().makeTangemPayAuthorizationServiceDecoder()
            ),
            tokens: tokens
        )
    }
}
