//
//  TangemPayAuthorizationServiceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct TangemPayAuthorizationServiceBuilder {
    private let apiType: VisaAPIType
    private let authorizationTokensRepository: TangemPayAuthorizationTokensRepository
    private let bffStaticToken: String

    public init(
        apiType: VisaAPIType,
        authorizationTokensRepository: TangemPayAuthorizationTokensRepository,
        bffStaticToken: String
    ) {
        self.apiType = apiType
        self.authorizationTokensRepository = authorizationTokensRepository
        self.bffStaticToken = bffStaticToken
    }

    public func build(
        customerWalletId: String,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> TangemPayAuthorizationService {
        CommonTangemPayAuthorizationService(
            customerWalletId: customerWalletId,
            authorizationTokensRepository: authorizationTokensRepository,
            apiType: apiType,
            apiService: TangemPayAPIService(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: bffStaticToken,
                    authorizationTokensHandler: nil,
                    configuration: urlSessionConfiguration
                ),
                decoder: makeDecoder(),
                responseFormat: .plain
            ),
            tokens: authorizationTokensRepository.getToken(forCustomerWalletId: customerWalletId)
        )
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
