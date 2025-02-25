//
//  VisaAPIServiceBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public struct VisaAPIServiceBuilder {
    private let mockedAPI: Bool

    public init(mockedAPI: Bool = false) {
        self.mockedAPI = mockedAPI
    }

    public func buildTransactionHistoryService(
        authorizationTokensHandler: VisaAuthorizationTokensHandler,
        isTestnet: Bool,
        urlSessionConfiguration: URLSessionConfiguration
    ) -> VisaTransactionHistoryAPIService {
        return CommonTransactionHistoryService(
            authorizationTokensHandler: authorizationTokensHandler,
            apiService: .init(
                provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                logger: InternalLogger(),
                decoder: JSONDecoderFactory().makePayAPIDecoder()
            )
        )
    }

    // Requirements are changed so this function will be also changed, but for now it is used for testing purposes
    public func buildAuthorizationService(urlSessionConfiguration: URLSessionConfiguration) -> VisaAuthorizationService {
        if mockedAPI {
            return AuthorizationServiceMock()
        }

        return AuthorizationServiceBuilder().build(urlSessionConfiguration: urlSessionConfiguration)
    }

    public func buildAuthorizationTokenRefreshService(urlSessionConfiguration: URLSessionConfiguration) -> VisaAuthorizationTokenRefreshService {
        if mockedAPI {
            return AuthorizationServiceMock()
        }

        return AuthorizationServiceBuilder().build(urlSessionConfiguration: urlSessionConfiguration)
    }
}
