//
//  VisaCardScanHandlerBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaCardScanHandlerBuilder {
    private let apiType: VisaAPIType
    private let isMockedAPIEnabled: Bool

    public init(apiType: VisaAPIType, isMockedAPIEnabled: Bool) {
        self.apiType = apiType
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    public func build(
        isTestnet: Bool,
        urlSessionConfiguration: URLSessionConfiguration,
        refreshTokenRepository: VisaRefreshTokenRepository
    ) -> VisaCardScanHandler {
        let authorizationService = VisaAPIServiceBuilder(
            apiType: apiType,
            isMockedAPIEnabled: isMockedAPIEnabled
        )
        .buildAuthorizationService(urlSessionConfiguration: urlSessionConfiguration)

        let cardActivationStateProvider = VisaCardActivationStatusServiceBuilder(
            apiType: apiType,
            isMockedAPIEnabled: isMockedAPIEnabled
        )
        .build(urlSessionConfiguration: urlSessionConfiguration)

        return .init(
            isTestnet: isTestnet,
            authorizationService: authorizationService,
            cardActivationStateProvider: cardActivationStateProvider,
            refreshTokenRepository: refreshTokenRepository
        )
    }
}
