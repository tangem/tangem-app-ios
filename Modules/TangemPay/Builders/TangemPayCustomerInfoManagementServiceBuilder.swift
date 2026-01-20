//
//  TangemPayCustomerInfoManagementServiceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct TangemPayCustomerInfoManagementServiceBuilder {
    private let apiType: VisaAPIType
    private let bffStaticToken: String

    public init(apiType: VisaAPIType, bffStaticToken: String) {
        self.apiType = apiType
        self.bffStaticToken = bffStaticToken
    }

    public func build(
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> CustomerInfoManagementService {
        CommonCustomerInfoManagementService(
            apiType: apiType,
            authorizationTokenHandler: authorizationTokensHandler,
            apiService: TangemPayAPIService(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: bffStaticToken,
                    authorizationTokensHandler: authorizationTokensHandler,
                    configuration: urlSessionConfiguration
                ),
                decoder: makeDecoder(),
                responseFormat: .wrapped
            )
        )
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatterA = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
            if let date = formatterA.date(from: dateString) {
                return date
            }

            let formatterB = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS")
            if let date = formatterB.date(from: dateString) {
                return date
            }

            // If neither format works, throw an error
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Date string does not match expected formats"
            )
        }

        return decoder
    }
}
