//
//  TangemPayAvailabilityServiceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct TangemPayAvailabilityServiceBuilder {
    private let apiType: VisaAPIType
    private let bffStaticToken: String

    public init(
        apiType: VisaAPIType,
        bffStaticToken: String
    ) {
        self.apiType = apiType
        self.bffStaticToken = bffStaticToken
    }

    public func build(
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> TangemPayAvailabilityService {
        CommonTangemPayAvailabilityService(
            apiType: apiType,
            apiService: TangemPayAPIService(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: bffStaticToken,
                    authorizationTokensHandler: nil,
                    configuration: urlSessionConfiguration
                ),
                decoder: makeDecoder(),
                responseFormat: .wrapped
            )
        )
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }
}
