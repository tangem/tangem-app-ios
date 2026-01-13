//
//  VisaAPIServiceBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils
import TangemPay

public struct VisaAPIServiceBuilder {
    private let apiType: TangemPayAPIType

    public init(apiType: TangemPayAPIType) {
        self.apiType = apiType
    }

    /// Requirements are changed so this function will be also changed, but for now it is used for testing purposes
    public func buildAuthorizationService(
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> VisaAuthorizationService {
        AuthorizationServiceBuilder(apiType: apiType).build(urlSessionConfiguration: urlSessionConfiguration)
    }

    public func buildAuthorizationTokenRefreshService(urlSessionConfiguration: URLSessionConfiguration) -> VisaAuthorizationTokenRefreshService {
        AuthorizationServiceBuilder(apiType: apiType).build(urlSessionConfiguration: urlSessionConfiguration)
    }
}
