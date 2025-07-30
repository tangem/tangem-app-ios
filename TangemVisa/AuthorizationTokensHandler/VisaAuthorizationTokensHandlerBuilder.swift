//
//  VisaAuthorizationTokensHandlerBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct VisaAuthorizationTokensHandlerBuilder {
    private let apiServiceBuilder: VisaAPIServiceBuilder

    public init(apiType: VisaAPIType, isMockedAPIEnabled: Bool) {
        apiServiceBuilder = VisaAPIServiceBuilder(
            apiType: apiType,
            isMockedAPIEnabled: isMockedAPIEnabled
        )
    }

    public func build(
        cardId: String,
        cardActivationStatus: VisaCardActivationLocalState,
        refreshTokenSaver: VisaRefreshTokenSaver?,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> VisaAuthorizationTokensHandler {
        let authorizationTokensHolder: AuthorizationTokensHolder
        if let authorizationTokens = cardActivationStatus.authTokens {
            authorizationTokensHolder = .init(authorizationTokens: authorizationTokens)
        } else {
            authorizationTokensHolder = .init()
        }

        let authorizationTokenRefreshService = apiServiceBuilder
            .buildAuthorizationTokenRefreshService(
                urlSessionConfiguration: urlSessionConfiguration
            )

        let authorizationTokensHandler = CommonVisaAuthorizationTokensHandler(
            cardId: cardId,
            authorizationTokensHolder: authorizationTokensHolder,
            tokenRefreshService: authorizationTokenRefreshService,
            refreshTokenSaver: refreshTokenSaver
        )

        return authorizationTokensHandler
    }

    public func build(visaAuthorizationTokens: VisaAuthorizationTokens) -> VisaAuthorizationTokensHandler {
        TangemPayAuthorizationTokensHandler(
            authorizationTokensHolder: AuthorizationTokensHolder(
                authorizationTokens: visaAuthorizationTokens
            )
        )
    }
}
