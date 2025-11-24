//
//  TangemPayAuthorizationTokensHandlerBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayAuthorizationTokensHandlerBuilder {
    private let apiServiceBuilder: TangemPayAPIServiceBuilder

    public init(apiType: VisaAPIType) {
        apiServiceBuilder = TangemPayAPIServiceBuilder(apiType: apiType)
    }
}

public extension TangemPayAuthorizationTokensHandlerBuilder {
    func buildTangemPayAuthorizationTokensHandler(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) -> TangemPayAuthorizationTokensHandler {
        CommonTangemPayAuthorizationTokensHandler(
            customerWalletId: customerWalletId,
            authorizationService: apiServiceBuilder.buildTangemPayAuthorizationService()
        )
    }
}
