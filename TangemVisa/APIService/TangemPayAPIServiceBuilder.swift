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

    public init(apiType: VisaAPIType) {
        self.apiType = apiType
    }
}

public extension TangemPayAPIServiceBuilder {
    func buildTangemPayAvailabilityService(
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> TangemPayAvailabilityService {
        CommonTangemPayAvailabilityService(
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
