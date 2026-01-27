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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let provider: TangemProvider<TangemPayAvailabilityAPITarget> = TangemPayProviderBuilder().buildProvider(
            configuration: urlSessionConfiguration,
            authorizationTokensHandler: nil
        )

        return CommonTangemPayAvailabilityService(
            apiType: apiType,
            apiService: APIService(provider: provider, decoder: decoder),
            bffStaticToken: bffStaticToken
        )
    }

    func buildTangemPayAuthorizationService(
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> TangemPayAuthorizationService {
        CommonTangemPayAuthorizationService(
            apiType: apiType,
            apiService: .init(
                provider: TangemPayProviderBuilder().buildProvider(
                    configuration: urlSessionConfiguration,
                    authorizationTokensHandler: nil
                ),
                decoder: JSONDecoderFactory().makeTangemPayAuthorizationServiceDecoder()
            )
        )
    }
}
