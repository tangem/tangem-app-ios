//
//  VisaAuthorizationTokensHandlerBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaAuthorizationTokensHandlerBuilder {
    private let isMockedAPIEnabled: Bool

    public init(isMockedAPIEnabled: Bool) {
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    public func build(
        cardId: String,
        cardActivationStatus: VisaCardActivationLocalState,
        refreshTokenSaver: VisaRefreshTokenSaver?,
        urlSessionConfiguration: URLSessionConfiguration,
        logger: VisaLogger
    ) -> VisaAuthorizationTokensHandler {
        let internalLogger = InternalLogger(logger: logger)

        let authorizationTokensHolder: AuthorizationTokensHolder
        if let authorizationTokens = cardActivationStatus.authTokens {
            authorizationTokensHolder = .init(authorizationTokens: authorizationTokens)
        } else {
            authorizationTokensHolder = .init()
        }

        let authorizationTokenRefreshService = VisaAPIServiceBuilder(mockedAPI: isMockedAPIEnabled)
            .buildAuthorizationTokenRefreshService(
                urlSessionConfiguration: urlSessionConfiguration,
                logger: logger
            )

        let authorizationTokensHandler = CommonVisaAuthorizationTokensHandler(
            cardId: cardId,
            authorizationTokensHolder: authorizationTokensHolder,
            tokenRefreshService: authorizationTokenRefreshService,
            logger: internalLogger,
            refreshTokenSaver: refreshTokenSaver
        )

        return authorizationTokensHandler
    }
}
