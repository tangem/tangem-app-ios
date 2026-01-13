//
//  TangemPayCustomerServiceBuilder.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils

public struct TangemPayCustomerServiceBuilder {
    private let apiType: TangemPayAPIType
    private let bffStaticToken: String

    public init(apiType: TangemPayAPIType, bffStaticToken: String) {
        self.apiType = apiType
        self.bffStaticToken = bffStaticToken
    }

    public func build(
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler,
        urlSessionConfiguration: URLSessionConfiguration = .tangemPayConfiguration
    ) -> TangemPayCustomerService {
        CommonTangemPayCustomerService(
            apiType: apiType,
            authorizationTokenHandler: authorizationTokensHandler,
            apiService: .init(
                provider: TangemPayProviderBuilder().buildProvider(
                    bffStaticToken: bffStaticToken,
                    authorizationTokensHandler: authorizationTokensHandler,
                    configuration: urlSessionConfiguration
                ),
                decoder: makeDecoder()
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
