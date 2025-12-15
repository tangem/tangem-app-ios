//
//  APIService.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct APIService<Target: TargetType> {
    private let provider: TangemProvider<Target>
    private var decoder: JSONDecoder

    init(
        provider: TangemProvider<Target>,
        decoder: JSONDecoder
    ) {
        self.provider = provider
        self.decoder = decoder
    }

    func request<T: Decodable>(_ request: Target) async throws -> T {
        var response: Response
        do {
            response = try await provider.asyncRequest(request)
        } catch {
            throw error
        }

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            let errorResponse = try decoder.decode(VisaAPIErrorResponse.self, from: response.data)
            throw errorResponse.error
        }

        do {
            let apiResponse = try decoder.decode(VisaAPIResponse<T>.self, from: response.data)
            return apiResponse.result
        } catch {
            throw error
        }
    }
}
