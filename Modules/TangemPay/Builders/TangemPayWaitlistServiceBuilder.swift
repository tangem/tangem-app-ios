//
//  TangemPayWaitlistServiceBuilder.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct TangemPayWaitlistServiceBuilder {
    private let apiType: VisaAPIType
    private let bffStaticToken: String

    public init(apiType: VisaAPIType, bffStaticToken: String) {
        self.apiType = apiType
        self.bffStaticToken = bffStaticToken
    }

    public func build(
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler? = nil,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> TangemPayWaitlistService {
        CommonTangemPayWaitlistService(
            apiType: apiType,
            apiService: TangemPayAPIService(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: bffStaticToken,
                    authorizationTokensHandler: authorizationTokensHandler,
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
        decoder.dateDecodingStrategy = .customISO8601
        return decoder
    }
}
