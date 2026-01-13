//
//  TangemPayAPIServiceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNetworkUtils
import TangemPay

public struct TangemPayAPIServiceBuilder {
    private let apiType: TangemPayAPIType
    private let bffStaticToken: String
    private let authorizationTokensRepository: TangemPayAuthorizationTokensRepository

    public init(
        apiType: TangemPayAPIType,
        bffStaticToken: String,
        authorizationTokensRepository: TangemPayAuthorizationTokensRepository
    ) {
        self.apiType = apiType
        self.bffStaticToken = bffStaticToken
        self.authorizationTokensRepository = authorizationTokensRepository
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
