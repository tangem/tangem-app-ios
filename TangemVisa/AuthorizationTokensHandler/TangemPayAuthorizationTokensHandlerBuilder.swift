//
//  TangemPayAuthorizationTokensHandlerBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayAuthorizationTokensHandlerBuilder {
    private let apiServiceBuilder: TangemPayAPIServiceBuilder

    public init(apiType: VisaAPIType, bffStaticToken: String) {
        apiServiceBuilder = TangemPayAPIServiceBuilder(
            apiType: apiType,
            bffStaticToken: bffStaticToken
        )
    }
}

public extension TangemPayAuthorizationTokensHandlerBuilder {
    func buildTangemPayAuthorizationTokensHandler(
        customerWalletId: String,
        tokens: TangemPayAuthorizationTokens?,
        authorizationService: TangemPayAuthorizationService,
        authorizationTokensRepository: TangemPayAuthorizationTokensRepository
    ) -> TangemPayAuthorizationTokensHandler {
        CommonTangemPayAuthorizationTokensHandler(
            customerWalletId: customerWalletId,
            tokens: tokens,
            authorizationService: apiServiceBuilder.buildTangemPayAuthorizationService(),
            authorizationTokensRepository: authorizationTokensRepository
        )
    }
}
