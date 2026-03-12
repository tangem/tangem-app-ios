//
//  VisaCardActivationStatusServiceBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

public struct VisaCardActivationStatusServiceBuilder {
    private let apiType: VisaAPIType

    public init(apiType: VisaAPIType) {
        self.apiType = apiType
    }

    public func build(urlSessionConfiguration: URLSessionConfiguration) -> VisaCardActivationStatusService {
        CommonCardActivationStatusService(
            apiType: apiType,
            apiService: TangemPayAPIService(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: "",
                    authorizationTokensHandler: nil,
                    configuration: urlSessionConfiguration
                ),
                decoder: JSONDecoder(),
                responseFormat: .wrapped
            )
        )
    }
}
