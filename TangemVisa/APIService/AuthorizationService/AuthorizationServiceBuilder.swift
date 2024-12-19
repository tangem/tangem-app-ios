//
//  AuthorizationServiceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Moya

struct AuthorizationServiceBuilder {
    func build(urlSessionConfiguration: URLSessionConfiguration, logger: VisaLogger) -> CommonVisaAuthorizationService {
        let logger = InternalLogger(logger: logger)

        return CommonVisaAuthorizationService(apiService: .init(
            provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
            logger: logger,
            decoder: JSONDecoderFactory().makePayAPIDecoder()
        ))
    }
}
