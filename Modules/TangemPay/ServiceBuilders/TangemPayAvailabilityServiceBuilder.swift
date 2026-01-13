//
//  TangemPayAvailabilityServiceBuilder.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils

public struct TangemPayAvailabilityServiceBuilder {
    private let apiType: TangemPayAPIType
    private let bffStaticToken: String

    public init(
        apiType: TangemPayAPIType,
        bffStaticToken: String
    ) {
        self.apiType = apiType
        self.bffStaticToken = bffStaticToken
    }

    public func build(
        urlSessionConfiguration: URLSessionConfiguration = .tangemPayConfiguration
    ) -> TangemPayAvailabilityService {
        CommonTangemPayAvailabilityService(
            apiService: TangemPayAPIService(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: bffStaticToken,
                    authorizationTokensHandler: nil,
                    configuration: urlSessionConfiguration
                ),
                decoder: makeDecoder()
            ),
            apiType: apiType
        )
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }
}
