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
    private let paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository

    public init(
        apiType: VisaAPIType,
        bffStaticToken: String,
        paeraCustomerFlagRepository: TangemPayPaeraCustomerFlagRepository
    ) {
        self.apiType = apiType
        self.bffStaticToken = bffStaticToken
        self.paeraCustomerFlagRepository = paeraCustomerFlagRepository
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
            ),
            paeraCustomerFlagRepository: paeraCustomerFlagRepository
        )
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }
}
