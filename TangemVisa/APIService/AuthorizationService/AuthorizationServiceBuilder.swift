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
        let provider = MoyaProvider<AuthorizationAPITarget>(session: Session(configuration: urlSessionConfiguration))

        return CommonVisaAuthorizationService(
            provider: provider,
            logger: logger
        )
    }
}
