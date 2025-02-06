//
//  ProductActivationServiceBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ProductActivationServiceBuilder {
    private let isMockAPIEnabled: Bool

    init(isMockAPIEnabled: Bool) {
        self.isMockAPIEnabled = isMockAPIEnabled
    }

    func build(urlSessionConfiguration: URLSessionConfiguration, authorizationTokensHandler: AuthorizationTokensHandler, logger: VisaLogger) -> ProductActivationService {
        if isMockAPIEnabled {
            return ProductActivationServiceMock()
        }

        let internalLogger = InternalLogger(logger: logger)

        return CommonProductActivationService(
            authorizationTokensHandler: authorizationTokensHandler,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                logger: internalLogger,
                decoder: JSONDecoder()
            )
        )
    }
}
