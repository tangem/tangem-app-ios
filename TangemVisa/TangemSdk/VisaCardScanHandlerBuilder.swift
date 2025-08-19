//
//  VisaCardScanHandlerBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct VisaCardScanHandlerBuilder {
    private let isTestnet: Bool
    private let apiServiceBuilder: VisaAPIServiceBuilder
    private let cardActivationStatusServiceBuilder: VisaCardActivationStatusServiceBuilder

    public init(apiType: VisaAPIType, isMockedAPIEnabled: Bool) {
        isTestnet = apiType.isTestnet
        apiServiceBuilder = VisaAPIServiceBuilder(
            apiType: apiType,
            isMockedAPIEnabled: isMockedAPIEnabled
        )
        cardActivationStatusServiceBuilder = VisaCardActivationStatusServiceBuilder(
            apiType: apiType,
            isMockedAPIEnabled: isMockedAPIEnabled
        )
    }

    public func build(
        refreshTokenRepository: VisaRefreshTokenRepository,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> VisaCardScanHandler {
        let authorizationService = apiServiceBuilder
            .buildAuthorizationService(urlSessionConfiguration: urlSessionConfiguration)

        let cardActivationStateProvider = cardActivationStatusServiceBuilder
            .build(urlSessionConfiguration: urlSessionConfiguration)

        return VisaCardScanHandler(
            authorizationService: authorizationService,
            cardActivationStateProvider: cardActivationStateProvider,
            refreshTokenRepository: refreshTokenRepository,
            isTestnet: isTestnet
        )
    }
}
