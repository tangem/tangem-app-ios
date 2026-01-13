//
//  TangemPayAuthorizationServiceBuilder.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct TangemPayAuthorizationServiceBuilder {
    private let apiType: TangemPayAPIType
    private let authorizationTokensRepository: TangemPayAuthorizationTokensRepository
    private let bffStaticToken: String

    public init(
        apiType: TangemPayAPIType,
        authorizationTokensRepository: TangemPayAuthorizationTokensRepository,
        bffStaticToken: String
    ) {
        self.apiType = apiType
        self.authorizationTokensRepository = authorizationTokensRepository
        self.bffStaticToken = bffStaticToken
    }

    public func build(
        customerWalletId: String,
        tokens: TangemPayAuthorizationTokens?,
        urlSessionConfiguration: URLSessionConfiguration = .tangemPayConfiguration
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
                decoder: makeDecoder()
            ),
            tokens: tokens
        )
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
