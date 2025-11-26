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

public struct VisaAPIServiceBuilder {
    private let isMockedAPIEnabled: Bool
    private let apiType: VisaAPIType

    public init(apiType: VisaAPIType, isMockedAPIEnabled: Bool) {
        self.apiType = apiType
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    public func buildTransactionHistoryService(
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> VisaTransactionHistoryAPIService {
        return CommonTransactionHistoryService(
            apiType: apiType,
            apiService: .init(
                provider: TangemPayProviderBuilder().buildProvider(
                    configuration: urlSessionConfiguration,
                    authorizationTokensHandler: authorizationTokensHandler
                ),
                decoder: JSONDecoderFactory().makePayAPIDecoder()
            )
        )
    }

    /// Requirements are changed so this function will be also changed, but for now it is used for testing purposes
    public func buildAuthorizationService(
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> VisaAuthorizationService {
        if isMockedAPIEnabled {
            return AuthorizationServiceMock()
        }

        return AuthorizationServiceBuilder(apiType: apiType).build(urlSessionConfiguration: urlSessionConfiguration)
    }

    public func buildAuthorizationTokenRefreshService(urlSessionConfiguration: URLSessionConfiguration) -> VisaAuthorizationTokenRefreshService {
        if isMockedAPIEnabled {
            return AuthorizationServiceMock()
        }

        return AuthorizationServiceBuilder(apiType: apiType).build(urlSessionConfiguration: urlSessionConfiguration)
    }
}
